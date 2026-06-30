terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
  backend "s3" {}
}

# ##############################
# Azure
# ##############################
provider "azurerm" {
  features {}
}

# ##############################
# Helm
# ##############################
provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
    client_certificate     = base64decode(yamldecode(module.aks.kube_config_raw).users[0].user["client-certificate-data"])
    client_key             = base64decode(yamldecode(module.aks.kube_config_raw).users[0].user["client-key-data"])
  }
}
