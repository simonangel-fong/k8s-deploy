### Istio Gateway + VirtualService

Frontend nginx no longer proxies `/api/` — Istio does the split at the edge:

- `deploy.arguswatcher.net/api/*` → backend
- `deploy.arguswatcher.net/*` → frontend

```sh
# 1. enable sidecar injection in both namespaces, then restart pods
kubectl label ns backend  istio-injection=enabled --overwrite
kubectl label ns frontend istio-injection=enabled --overwrite
kubectl rollout restart deploy/backend  -n backend
kubectl rollout restart deploy/frontend -n frontend
kubectl get po -n backend  -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IP             NODE                              NOMINATED NODE   READINESS GATES
# backend-d9fd66d48-5sqrq   2/2     Running   0          7s    10.244.1.157   aks-default-14028782-vmss000000   <none>           <none>
kubectl get po -n frontend -o wide
# NAME                        READY   STATUS    RESTARTS   AGE   IP            NODE                              NOMINATED NODE   READINESS GATES
# frontend-754c4f9787-dvcj8   2/2     Running   0          20s   10.244.1.23   aks-default-14028782-vmss000000   <none>           <none>

# 2. discover the ingress LB IP
kubectl get svc -n istio-ingress istio-gateway
# NAME            TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)                                      AGE
# istio-gateway   LoadBalancer   10.0.118.109   130.107.229.119   15021:32522/TCP,80:31492/TCP,443:31279/TCP   5m11s


# 3. verify
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/healthz/
# ok
```

### Phase 05 — AuthorizationPolicy + STRICT mTLS

Locks down `backend` and `frontend` at L7 (Envoy):

- **PeerAuthentication STRICT** — non-mTLS connections rejected. Kubelet probes bypass sidecar (Istio rewrites them), so probes keep working.
- **AuthorizationPolicy ALLOW** — only requests from the ingress gateway SPIFFE identity `cluster.local/ns/istio-ingress/sa/istio-gateway` are permitted, to expected paths only.
- Anything else → **403 RBAC: access denied**.

Enabled via `security.enabled: true` in each app chart's values.

```sh
# after push + argo sync

# positive: still works through the gateway
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/

# negative: in-cluster call from a random pod should be denied
kubectl run -n default --rm -it debug --image=curlimages/curl --restart=Never -- curl -sv http://backend.backend.svc.cluster.local/api/
# * Host backend.backend.svc.cluster.local:80 was resolved.
# * IPv6: (none)
# * IPv4: 10.0.190.94
# *   Trying 10.0.190.94:80...
# * Established connection to backend.backend.svc.cluster.local (10.0.190.94 port 80) from 10.244.0.18 port 54590
# * using HTTP/1.x
# > GET /api/ HTTP/1.1
# > Host: backend.backend.svc.cluster.local
# > User-Agent: curl/8.21.0
# > Accept: */*
# >
# * Request completely sent off
# * Recv failure: Connection reset by peer
# * closing connection #0
# pod "debug" deleted from default namespace
# pod default/debug terminated (Error)

# check what got applied
kubectl get authorizationpolicy,peerauthentication -A
# NAMESPACE   NAME                                             ACTION   AGE
# backend     authorizationpolicy.security.istio.io/backend    ALLOW    2m1s
# frontend    authorizationpolicy.security.istio.io/frontend   ALLOW    2m16s

# NAMESPACE   NAME                                           MODE     AGE
# backend     peerauthentication.security.istio.io/default   STRICT   2m1s
# frontend    peerauthentication.security.istio.io/default   STRICT   2m16s
```

### Phase 06 — TLS via cert-manager + Let's Encrypt

Cloudflare A record is DNS-only (grey cloud) so LE HTTP-01 can reach the origin.
Staging issuer to start (browser will warn — expected); switch to prod later by editing `tls.issuer.server` in [app/gateway/values.yaml](app/gateway/values.yaml).

**Two-step rollout** because `httpsRedirect: true` would break the HTTP-01 challenge:

**Step A** — TLS on :443, no redirect yet.

```sh
# values.yaml: tls.enabled=true, tls.httpsRedirect=false
git push  # argo syncs cert-manager, ClusterIssuer, Certificate, :443 listener

# watch the cert issue (staging is fast; ~30–60s)
kubectl -n istio-ingress get certificate
# NAME        READY   SECRET       AGE
# demo-cert   True    deploy-tls   25s


# once READY=True, test HTTPS (staging cert is untrusted → -k)
curl -k -s --resolve deploy.arguswatcher.net:443:130.107.229.119 https://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
curl -k -s --resolve deploy.arguswatcher.net:443:130.107.229.119 https://deploy.arguswatcher.net/

# HTTP still works (no redirect yet)
curl -s --resolve deploy.arguswatcher.net:80:130.107.229.119  http://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
```

**Step B** — enable redirect.

```sh
# flip tls.httpsRedirect=true in app/gateway/values.yaml, push
# HTTP now 301s to HTTPS
curl -i --resolve deploy.arguswatcher.net:80:130.107.229.119 http://deploy.arguswatcher.net/
# HTTP/1.1 200 OK
# server: istio-envoy
# date: Wed, 01 Jul 2026 20:39:26 GMT
# content-type: text/html
# content-length: 1016
# last-modified: Wed, 01 Jul 2026 20:21:04 GMT
# etag: "6a4576b0-3f8"
# accept-ranges: bytes
# x-envoy-upstream-service-time: 0

```

---

## Runbook

```sh
kubectl -n istio-ingress get certificaterequest,order,challenge

kubectl -n istio-ingress describe challenge
```

- No Challenge object exists, Order is stuck → issuer/DNS/ACME registration problem.
- Challenge exists, state = pending, reason mentions "self check failed" or HTTP 404 → the http01.ingress.class: istio solver created an Ingress but Istio isn't routing it. This is the most likely case given your setup.
- Challenge shows "no such host" / DNS error → deploy.arguswatcher.net doesn't resolve to your ingress IP yet.
