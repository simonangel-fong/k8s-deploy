# module "aks" {
#   source = "git::https://github.com/simonangel-fong/terraform-template.git//azure/aks"

#   project_name        = "demo"
#   env                 = "dev"
#   resource_group_name = "demo-rg"
#   location            = "eastus"

#   admin_group_object_ids = ["00000000-0000-0000-0000-000000000000"]

#   default_node_pool = {
#     vm_size    = "Standard_D2s_v3"
#     node_count = 2
#   }

#   tags = {
#     owner = "platform-team"
#   }
# }
