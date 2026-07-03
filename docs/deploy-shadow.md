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
while true; do
  printf '%s ' "$(date +%T)"
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

kubectl -n backend logs -f -l app.kubernetes.io/name=backend-shadow,rollouts-pod-template-hash=<CANARY_HASH> --prefix=true --tail=0
# [pod/backend-shadow-59f868b86b-pjj27/backend-shadow] 127.0.0.6 - - [02/Jul/2026:19:18:45 +0000] "GET /api/ HTTP/1.1" 200 46 "-" "curl/8.5.0" "99.243.74.50,10.10.0.4,10.244.0.141"
# [pod/backend-shadow-59f868b86b-pjj27/backend-shadow] {"time":"2026-07-02T19:18:45+00:00","ver":"V4.0.1","method":"GET","uri":"/api/","status":200,"xff":"99.243.74.50,10.10.0.4,10.244.0.141","ua":"curl/8.5.0"}
# [pod/backend-shadow-59f868b86b-pjj27/backend-shadow] 127.0.0.6 - - [02/Jul/2026:19:18:46 +0000] "GET /api/ HTTP/1.1" 200 46 "-" "curl/8.5.0" "99.243.74.50,10.10.0.5,10.244.0.141"
# [pod/backend-shadow-59f868b86b-pjj27/backend-shadow] {"time":"2026-07-02T19:18:46+00:00","ver":"V4.0.1","method":"GET","uri":"/api/","status":200,"xff":"99.243.74.50,10.10.0.5,10.244.0.141","ua":"curl/8.5.0"}
# [pod/backend-shadow-59f868b86b-pjj27/backend-shadow] 127.0.0.6 - - [02/Jul/2026:19:18:47 +0000] "GET /api/ HTTP/1.1" 200 46 "-" "curl/8.5.0" "99.243.74.50,10.10.0.5,10.244.0.141"

# When satisfied, promote to advance past the manual gate
kubectl argo rollouts promote backend-shadow -n backend
# rollout 'backend-shadow' promoted

# Full promote or rollback
kubectl argo rollouts promote backend-shadow -n backend    # or `undo`

```
