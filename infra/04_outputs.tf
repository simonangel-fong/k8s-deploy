# outputs.tf

output "kubeconfig_aks" {
  description = "Update local kubeconfig with AKS"
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${module.aks.cluster_name} --overwrite-existing"
}
