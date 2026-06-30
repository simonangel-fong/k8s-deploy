# variables.tf

# ##############################
# Metadata
# ##############################
variable "project_name" {
  type = string
}

variable "env" {
  type = string
}

# ##############################
# AKS
# ##############################
variable "resource_group_name" {
  description = "Name of an existing resource group to deploy the cluster into."
  type        = string
}

variable "location" {
  description = "Azure region for the cluster. Must match the resource group's region."
  type        = string
}
