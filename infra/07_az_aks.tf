# aks.tf

resource "azuread_group" "aks_admins_group" {
  display_name     = local.common_name
  security_enabled = true
  description      = "Members of this group have administrative access to the AKS cluster."
}

module "aks" {
  source = "git::https://github.com/simonangel-fong/terraform-template.git//azure/aks"

  aks_name            = local.common_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  admin_group_object_ids = [azuread_group.aks_admins_group.object_id]
  default_node_pool = {
    vm_size        = "standard_dc2s_v3"
    node_count     = 2
    vnet_subnet_id = azurerm_subnet.main.id
  }

  tags = merge(
    { name = local.common_name },
    local.default_tags
  )
}
