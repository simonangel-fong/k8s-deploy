# Deployment - Rolling

[Back](../README.md)

- [Deployment - Rolling](#deployment---rolling)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-rolling

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
argocd app diff app-02-backend-rolling

# watch pod transitions
kubectl get po -n backend -l app.kubernetes.io/name=backend-rolling -w

# constant traffic
while true; do
  printf '%s ' "$(date +%T)"
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done




```
