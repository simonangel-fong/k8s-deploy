# Kubernetes Deployment Playbook: Infrastructure as Code with Terraform

[Back](../README.md)

- [Kubernetes Deployment Playbook: Infrastructure as Code with Terraform](#kubernetes-deployment-playbook-infrastructure-as-code-with-terraform)
  - [AKS - Design](#aks---design)
  - [Development](#development)
    - [Terraform](#terraform)
    - [Connect Cluster](#connect-cluster)

---

## AKS - Design

- VNet:
  - cidr: `10.10.0.0/16`
  - ip nubmer: 65,536

- Terraform module url:
  - https://github.com/simonangel-fong/terraform-template.git//azure/aks_dev

---

## Development

### Terraform

```sh
# init with remote backend
terraform -chdir=infra init --backend-config=backend.hcl --upgrade
# format and validate
terraform -chdir=infra fmt && terraform -chdir=infra validate

# apply
terraform -chdir=infra apply --auto-approve
terraform -chdir=infra output

# destroy
terraform -chdir=infra destroy --auto-approve
```

---

### Connect Cluster

```sh
# update kubeconfig
az aks get-credentials --resource-group rg-general --name k8s-deploy-dev --overwrite-existing

# set env var
export KUBECONFIG=~/kubeconfig
kubectl get node
# NAME                              STATUS   ROLES    AGE   VERSION
# aks-default-67386939-vmss000000   Ready    <none>   10h   v1.35.5
# aks-default-67386939-vmss000001   Ready    <none>   10h   v1.35.5
```
