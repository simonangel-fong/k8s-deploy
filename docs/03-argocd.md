# Kubernetes Deployment Playbook: ArgoCD

[Back](../README.md)

- [Kubernetes Deployment Playbook: ArgoCD](#kubernetes-deployment-playbook-argocd)
  - [Deveopment](#deveopment)

---

Install Argo CD and use the app-of-apps pattern to deploy Envoy Gateway and `demo-api` declaratively.

## Deveopment

```sh
export KUBECONFIG=~/kubeconfig
az aks get-credentials --resource-group rg-general --name k8s-deploy-dev --overwrite-existing -f $KUBECONFIG

helm install argocd argo/argo-cd --namespace argocd --create-namespace

# get init pwd
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo
# port forward argocd UI
kubectl port-forward service/argocd-server -n argocd 8080:443

# install app-of-apps
kubectl apply -f argocd/00-root.yaml

# login
argocd login localhost:8080
argocd app list

```
