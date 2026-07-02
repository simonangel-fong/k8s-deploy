# Deployment - Blue-Green: Header-based Preview Lane

[Back](../README.md)

- [Deployment - Blue-Green: Header-based Preview Lane](#deployment---blue-green-header-based-preview-lane)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-blue-green

# Visualization
# argocd
kubectl -n argocd port-forward svc/argocd-server 8080:443
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
# Watch the rollout status
kubectl argo rollouts get rollout backend -n backend -w

# 1. Trigger a new version by editing app/backend-blue-green/values.yaml (api.version)
#    and letting Argo CD sync. The new ReplicaSet comes up on the preview lane.

# 2. Active lane still serves the old version:
while true; do
  printf '%s active  ' "$(date +%T)"
  curl -sw '\n' https://deploy.arguswatcher.net/api/
  sleep 0.5
done

# 3. Preview lane serves the new version — validate here before promoting:
while true; do
  printf '%s preview ' "$(date +%T)"
  curl -sw '\n' -H 'x-preview: true' https://deploy.arguswatcher.net/api/
  sleep 0.5
done

# 4. When happy, flip production traffic to the new ReplicaSet:
kubectl argo rollouts promote backend-backend-blue-green -n backend

# 5. Old ReplicaSet stays for scaleDownDelaySeconds (120s) — abort within that
#    window to roll back instantly:
kubectl argo rollouts undo backend-backend-blue-green -n backend
```
