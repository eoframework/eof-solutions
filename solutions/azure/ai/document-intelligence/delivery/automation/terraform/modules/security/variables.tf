#------------------------------------------------------------------------------
# Security Module - Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "key_vault_id" {
  description = "ID of the Key Vault"
  type        = string
}

variable "security" {
  description = "Security configuration"
  type = object({
    enable_customer_managed_key = bool
    admin_group_id              = string
    reviewer_group_id           = string
    user_group_id               = string
  })
}
