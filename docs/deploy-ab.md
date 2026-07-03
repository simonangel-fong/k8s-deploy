# Deployment - A/B Test

[Back](../README.md)

- [Deployment - A/B Test](#deployment---ab-test)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-ab

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
# promote
kubectl argo rollouts promote backend-ab -n backend

# constant traffic
while true; do
  printf '%s variant a&b ' "$(date +%T)"
  curl -sw '\n' https://deploy.arguswatcher.net/api/
  sleep 0.5
done
# 14:12:38 variant a&b {"app":"demo app - a/b","version":"V3.0.0"}
# 14:12:38 variant a&b {"app":"demo app - a/b","version":"V3.0.0"}
# 14:12:39 variant a&b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:12:40 variant a&b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:12:40 variant a&b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:12:41 variant a&b {"app":"demo app - a/b","version":"V3.0.0"}
# 14:12:42 variant a&b {"app":"demo app - a/b","version":"V3.0.0"}
# 14:12:42 variant a&b {"app":"demo app - a/b","version":"V3.0.0"}
# 14:12:43 variant a&b {"app":"demo app - a/b","version":"V3.0.1"}

# variant-b request
while true; do
  printf '%s variant-b ' "$(date +%T)"
  curl -sw '\n' -H 'x-variant: b' https://deploy.arguswatcher.net/api/
  sleep 0.5
done
# 14:11:10 variant-b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:11:11 variant-b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:11:12 variant-b {"app":"demo app - a/b","version":"V3.0.1"}
# 14:11:12 variant-b {"app":"demo app - a/b","version":"V3.0.1"}


kubectl argo rollouts undo backend-ab -n backend
# rollout 'backend-ab' undo

```
