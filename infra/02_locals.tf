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
  # cluster
  # ##############################
  kubernetes_version = "1.30"
}
