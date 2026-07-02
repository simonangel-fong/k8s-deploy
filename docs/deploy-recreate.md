# Deployment - Recreate

[Back](../README.md)

- [Deployment - Recreate](#deployment---recreate)
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
# Terminal 1: watch pods vanish then reappear
kubectl get po -n backend -l app.kubernetes.io/name=backend-recreate -w

# Terminal 2: measure the outage window
while true; do
  printf '%s ' "$(date +%T)"
  curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' \
    https://deploy.arguswatcher.net/api/
  sleep 0.5
done
```
