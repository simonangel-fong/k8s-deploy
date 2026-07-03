# Deployment - Canary(Host-level Traffic Splitting)

[Back](../README.md)

- [Deployment - Canary(Host-level Traffic Splitting)](#deployment---canaryhost-level-traffic-splitting)
  - [Preparation](#preparation)
  - [Rollout](#rollout)

---

## Preparation

```sh
helm lint app/backend-canary-multisvc
# ==> Linting app/backend-canary-multisvc
# [INFO] Chart.yaml: icon is recommended

# 1 chart(s) linted, 0 chart(s) failed

# Visualization
# argocd
kubectl -n argocd port-forward svc/argocd-server 8080:443
# argo rollouts
kubectl -n argo-rollouts port-forward svc/argo-rollouts-dashboard 31000:3100
# kiali
kubectl -n istio-system port-forward svc/kiali 20001:20001
# grafana
kubectl -n istio-system port-forward svc/grafana 3000:3000
```

---

## Rollout

```sh
# sync app
argocd app sync app-02-backend-canary-multisvc

# confirm pod transitions
kubectl get po -n backend -l app.kubernetes.io/name=backend-canary-multisvc -w

# constant traffic
while true; do
  printf '%s ' "$(date +%T)"
  curl -s https://deploy.arguswatcher.net/api/
  echo
  sleep 0.5
done
# 10:44:27 {"app":"demo app - backend-canary-multisvc","version":"V3.0.0"}
# 10:44:28 {"app":"demo app - backend-canary-multisvc","version":"V3.1.0"}
# 10:44:28 {"app":"demo app - backend-canary-multisvc","version":"V3.0.0"}
# 10:44:29 {"app":"demo app - backend-canary-multisvc","version":"V3.0.0"}
# 10:44:30 {"app":"demo app - backend-canary-multisvc","version":"V3.0.0"}
# 10:44:30 {"app":"demo app - backend-canary-multisvc","version":"V3.0.0"}
# 10:44:31 {"app":"demo app - backend-canary-multisvc","version":"V3.1.0"}
# 10:44:32 {"app":"demo app - backend-canary-multisvc","version":"V3.1.0"}
```

![canary: argorollout gif](./img/canary_argorollout.gif)

![canary: kiali gif](./img/canary_kiali.gif)
