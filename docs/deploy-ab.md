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
# promote
kubectl argo rollouts promote backend -n backend

# constant request
while true; do
  curl https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

# header request
while true; do
  curl -H 'x-variant: b' https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

```
