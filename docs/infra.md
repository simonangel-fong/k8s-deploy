
```sh
terraform -chdir=infra init --backend-config=backend.hcl --upgrade
terraform -chdir=infra fmt && terraform -chdir=infra validate

terraform -chdir=infra apply --auto-approve
terraform -chdir=infra output

terraform -chdir=infra destroy --auto-approve


az aks get-credentials --resource-group rg_general --name argo-istio-dev --overwrite-existing

export KUBECONFIG=~/kubeconfig
kubectl get node


```

## ArgoCD

```sh
export KUBECONFIG=~/kubeconfig
helm install argocd argo/argo-cd --namespace argocd --create-namespace

kubectl port-forward service/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode; echo


```