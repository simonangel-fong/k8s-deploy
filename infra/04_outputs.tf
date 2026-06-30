# outputs.tf

output "rg_name" {
  value = data.azurerm_resource_group.main.name
}
