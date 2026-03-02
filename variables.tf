# The Azure region where resources will be deployed
variable "location" {
  type        = string
  default     = "West Europe"
  description = "The Azure region for all resources."
}

# The name of the Resource Group
variable "resource_group_name" {
  type        = string
  default     = "azure-project-rg"
  description = "Name of the resource group."
}

# Name for the first Virtual Network
variable "vnet_a_name" {
  type        = string
  default     = "vnet-a"
  description = "Name of the first VNet."
}

# Name for the second Virtual Network
variable "vnet_b_name" {
  type        = string
  default     = "vnet-b"
  description = "Name of the second VNet."
}