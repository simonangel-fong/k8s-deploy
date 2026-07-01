# App Plan

## Goal

- Backend API served by nginx, packaged as a Helm chart.
- Frontend web served by nginx, packaged as a Helm chart, calling the backend.

## Scope

- **In scope:** Helm charts, manifests, app logic.
- **Out of scope:** k8s cluster provisioning, Argo CD install.
- **Deploy target:** Argo CD (later phase); Helm CLI during development.
- **Layout:**
  - `app/backend/`
  - `app/frontend/`

---

## Backend

Static responses served by nginx (no app runtime).

| Method | Path        | Response                                        |
| ------ | ----------- | ----------------------------------------------- |
| GET    | `/api/`     | `{"app": "demo app", "version": "V1.0.0"}` (v1) |
| GET    | `/api/`     | `{"app": "demo app", "version": "V2.0.0"}` (v2) |
| GET    | `/healthz/` | `ok`                                            |

Version is switched via image tag / chart value, not by routing.

---

## Frontend

- Static HTML served by nginx.
- On load, fetches `/api/` from backend and renders:
  - `App name: demo app`
  - `Version: V1.0.0`
- Backend URL is configurable via Helm values (ConfigMap → HTML/JS).

---

## Phases

### Phase 01 — Backend skeleton

- `helm create backend`, strip to:
  - `deployment.yaml`, `service.yaml`
  - `values.yaml` with `replicaCount: 1` only
- Deploy via Helm CLI.
- **Verify:** `helm status` healthy; `kubectl port-forward` shows nginx default page.

### Phase 02 — Backend API

- Add ConfigMap with `nginx.conf` + JSON responses for `/api/` and `/healthz/`.
- Deploy via Helm CLI.
- **Verify:** `port-forward` → `curl /api/` and `curl /healthz/` return expected payloads.

### Phase 03 — Frontend

- Copy backend chart as starting point.
- Add ConfigMap with `index.html` that fetches backend `/api/` and renders it.
- Deploy via Helm CLI.
- **Verify:** `port-forward` → browser shows app name + version pulled from backend.

---

## Development

### Phase 01 — Backend skeleton

```sh
mkdir -pv app/backend

helm create app/backend
# Creating app/backend

cd app/backend/templates
rm hpa.yaml ingress.yaml serviceaccount.yaml NOTES.txt
rm -r tests/
cd -

helm lint app/backend

helm install backend app/backend -n backend --create-namespace

# confirm
helm status backend -n backend
kubectl get pods,svc -n backend
kubectl port-forward -n backend svc/backend 8080:80

# Cleanup between iterations
helm uninstall backend -n backend
```

### Phase 02 — Backend API

```sh
helm template backend app/backend

helm lint app/backend

# Upgrade the release from Phase 01
helm upgrade backend app/backend -n backend

# confirm
kubectl rollout status deploy/backend -n backend
kubectl port-forward -n backend svc/backend 8080:80

# in another shell
curl -s http://localhost:8080/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s http://localhost:8080/healthz/
# ok

# switch to v2 without editing values.yaml
helm upgrade backend app/backend -n backend --set api.version=V2.0.0
curl -s http://localhost:8080/api/
# {"app":"demo app","version":"V2.0.0"}
```

### Phase 03 — Frontend

Frontend nginx serves `index.html` and proxies `/api/` to the backend service (same-origin, no CORS).
`backend.host` defaults to `backend` — assumes frontend runs in the same namespace as the backend service.

```sh
helm template frontend app/frontend

helm lint app/frontend

# install alongside backend (same namespace so DNS resolves)
helm install frontend app/frontend -n backend

# confirm
kubectl rollout status deploy/frontend -n backend
kubectl port-forward -n backend svc/frontend 8081:80

# browser: http://localhost:8081 → shows "demo app" + version from backend
# or from CLI:
curl -s http://localhost:8081/          # HTML page
curl -s http://localhost:8081/api/      # proxied to backend
curl -s http://localhost:8081/healthz/  # ok


```

### Phase 04 — Istio Gateway + VirtualService

Frontend nginx no longer proxies `/api/` — Istio does the split at the edge:

- `deploy.arguswatcher.net/api/*` → backend
- `deploy.arguswatcher.net/*`     → frontend

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
# NAME            TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                                      AGE
# istio-gateway   LoadBalancer   10.0.45.253   130.107.8.143   15021:30242/TCP,80:32187/TCP,443:32165/TCP   21m

# 3. verify
curl -s --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/
curl -s --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/healthz/
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
curl -s --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/api/
# {"app":"demo app","version":"V1.0.0"}
curl -s --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/

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
kubectl -n istio-ingress get certificate deploy -w
kubectl -n istio-ingress describe certificate deploy | tail -30

# once READY=True, test HTTPS (staging cert is untrusted → -k)
curl -k -s --resolve deploy.arguswatcher.net:443:130.107.8.143 https://deploy.arguswatcher.net/api/
curl -k -s --resolve deploy.arguswatcher.net:443:130.107.8.143 https://deploy.arguswatcher.net/

# HTTP still works (no redirect yet)
curl    -s --resolve deploy.arguswatcher.net:80:130.107.8.143  http://deploy.arguswatcher.net/api/
```

**Step B** — enable redirect.

```sh
# flip tls.httpsRedirect=true in app/gateway/values.yaml, push
# HTTP now 301s to HTTPS
curl -i --resolve deploy.arguswatcher.net:80:130.107.8.143 http://deploy.arguswatcher.net/
# HTTP/1.1 301 Moved Permanently
# location: https://deploy.arguswatcher.net/
```

**Switch to production Let's Encrypt** once staging works end-to-end:

```yaml
# app/gateway/values.yaml
tls:
  issuer:
    server: https://acme-v02.api.letsencrypt.org/directory
```

Then delete the staging cert Secret so a fresh prod cert is issued:

```sh
kubectl -n istio-ingress delete secret deploy-tls
# cert-manager reissues from prod → browser trusts it, remove -k from curl
```





