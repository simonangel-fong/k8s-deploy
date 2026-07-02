# Deployment - Canary: Host-level Traffic Splitting

[Back](../README.md)

- [Deployment - Canary: Host-level Traffic Splitting](#deployment---canary-host-level-traffic-splitting)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-canary-multisvc
helm lint app/backend-canary-multdest

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
# active
kubectl argo rollouts promote backend -n backend

while true; do
  curl https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

# preview
while true; do
  curl -H 'x-preview: true' https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

```
