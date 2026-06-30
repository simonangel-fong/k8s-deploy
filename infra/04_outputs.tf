# outputs.tf

output "kubeconfig_cmd" {
  value = module.aks.kubeconfig_cmd
}
