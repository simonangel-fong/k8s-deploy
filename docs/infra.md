```sh
terraform -chdir=infra init --backend-config=backend.hcl --upgrade
terraform -chdir=infra fmt && terraform -chdir=infra validate

terraform -chdir=infra apply --auto-approve
terraform -chdir=infra output

terraform -chdir=infra destroy --auto-approve


az aks get-credentials --resource-group rg-general --name k8s-deploy-dev --overwrite-existing

export KUBECONFIG=~/kubeconfig
kubectl get node


```

