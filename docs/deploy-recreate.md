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
# sync app
argocd app sync app-02-backend-rolling

# confirm pod transitions
kubectl get po -n backend -l app.kubernetes.io/name=backend-recreate -w

# Terminal 2: measure the outage window
while true; do
  printf '%s ' "$(date +%T)"
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

# 15:55:34 {"app":"demo app - recreate","version":"V6.0.0"}
# 15:55:35 {"app":"demo app - recreate","version":"V6.0.0"}
# 15:55:36 {"app":"demo app - recreate","version":"V6.0.0"}
# 15:55:36 {"app":"demo app - recreate","version":"V6.0.0"}
# 15:55:37 no healthy upstream
# 15:55:37 no healthy upstream
# 15:55:38 no healthy upstream
# 15:55:39 no healthy upstream
# 15:55:39 no healthy upstream
# 15:55:40 no healthy upstream
# 15:55:40 no healthy upstream
# 15:55:41 no healthy upstream
# 15:55:42 {"app":"demo app - recreate","version":"V6.0.1"}
# 15:55:42 {"app":"demo app - recreate","version":"V6.0.1"}
# 15:55:43 {"app":"demo app - recreate","version":"V6.0.1"}
# 15:55:44 {"app":"demo app - recreate","version":"V6.0.1"}
# 15:55:44 {"app":"demo app - recreate","version":"V6.0.1"}

```

![recreate: argocd gif](./img/recreate_argocd.gif)

![recreate: curl gif](./img/recreate_curl.gif)
