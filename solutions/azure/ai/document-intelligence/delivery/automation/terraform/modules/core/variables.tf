#------------------------------------------------------------------------------
# Core Infrastructure Module - Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "network" {
  description = "Network configuration"
  type = object({
    vnet_cidr                = string
    subnet_functions         = string
    subnet_private_endpoints = string
    enable_private_endpoints = bool
  })
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "object_id" {
  description = "Object ID of the deployer"
  type        = string
}
