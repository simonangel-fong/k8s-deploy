# Deployment - Rolling

[Back](../README.md)

- [Deployment - Rolling](#deployment---rolling)
  - [Preparation](#preparation)
  - [Test](#test)

---

## Preparation

```sh
helm lint app/backend-rolling
# ==> Linting app/backend-rolling
# [INFO] Chart.yaml: icon is recommended

# 1 chart(s) linted, 0 chart(s) failed

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

## Test

```sh
# sync app
argocd app sync app-02-backend-rolling

# confirm pod transitions
kubectl get po -n backend -l app.kubernetes.io/name=backend-rolling -w

# constant traffic
while true; do
  printf '%s ' "$(date +%T)"
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done

# 22:49:14 {"app":"demo app - rolling","version":"V1.0.0"}
# 22:49:15 {"app":"demo app - rolling","version":"V1.0.0"}
# 22:49:15 {"app":"demo app - rolling","version":"V1.1.0"}
# 22:49:16 {"app":"demo app - rolling","version":"V1.1.0"}
# 22:49:16 {"app":"demo app - rolling","version":"V1.1.0"}
# 22:49:17 {"app":"demo app - rolling","version":"V1.1.0"}
# 22:49:18 {"app":"demo app - rolling","version":"V1.0.0"}
# 22:49:18 {"app":"demo app - rolling","version":"V1.1.0"}
# 22:49:19 {"app":"demo app - rolling","version":"V1.1.0"}

```

![pic](./img/rolling_argocd.gif)

![pic](./img/rolling_curl.gif)
