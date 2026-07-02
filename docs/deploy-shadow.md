# Deployment - Shadow

[Back](../README.md)

- [Deployment - Shadow](#deployment---shadow)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-ab

# Visualization
# argocd
kubectl -n istio-system port-forward svc/kiali 8080:443
# argo rollouts
kubectl -n argo-rollouts port-forward svc/argo-rollouts-dashboard 3100:3100
# kiali
kubectl -n istio-system port-forward svc/kiali 20001:20001
# grafana
kubectl -n istio-system port-forward svc/grafana 3000:3000
```

---

## Rollout

```sh
# 1. Watch canary pod access logs — these are the mirrored requests
kubectl logs -n backend -l app.kubernetes.io/name=backend-shadow -f | jq .

# 2. In another terminal, drive traffic against the primary
while true; do
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

# 3. Observe: client always sees V<previous>, but every request shows
#    up in the canary pod's log with V4.0.0 — that's Istio dropping
#    the mirror response and forwarding stable's.

# 4. When satisfied, promote to advance past the manual gate
kubectl argo rollouts promote backend-shadow -n backend

# 5. Rollout auto-ramps 10% → 2m → 50%, then holds for final promote

# 6. Full promote or rollback
kubectl argo rollouts promote backend-shadow -n backend    # or `undo`


```
