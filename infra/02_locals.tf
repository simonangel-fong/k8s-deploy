locals {
  # ##############################
  # Metadata
  # ##############################
  common_name = "${var.project_name}-${var.env}"
  default_tags = {
    Project     = var.project_name
    Environment = var.env
    ManagedBy   = "Terraform"
  }

  # ##############################
  # Networking
  # ##############################
  vnet_cidr = "10.10.0.0/16"
  # /20 = 4,096 addresses for the AKS node/pod subnet
  subnet_cidr = cidrsubnet(local.vnet_cidr, 4, 0)

  # ##############################
  # cluster
  # ##############################
}
