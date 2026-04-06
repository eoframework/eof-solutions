#------------------------------------------------------------------------------
# Processing Module - Variables
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

variable "function_config" {
  description = "Function App configuration"
  type = object({
    name_prefix     = string
    runtime         = string
    runtime_version = string
    sku             = string
    min_instances   = number
    max_instances   = number
  })
}

variable "subnet_id" {
  description = "Subnet ID for VNet integration (null if disabled)"
  type        = string
  default     = null
}

variable "storage_account_name" {
  description = "Storage account name for Function App"
  type        = string
}

variable "storage_connection_string" {
  description = "Storage account connection string"
  type        = string
  sensitive   = true
}

variable "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  type        = string
}

variable "cosmos_key" {
  description = "Cosmos DB key"
  type        = string
  sensitive   = true
}

variable "key_vault_uri" {
  description = "Key Vault URI"
  type        = string
}

variable "managed_identity_id" {
  description = "Managed identity ID for Function App"
  type        = string
}

variable "application" {
  description = "Application settings"
  type = object({
    environment          = string
    log_level            = string
    confidence_threshold = number
  })
}

variable "docintel" {
  description = "Azure Document Intelligence configuration"
  type = object({
    sku                 = string
    model_invoice       = string
    model_receipt       = string
    model_custom        = optional(string, "")
    enable_custom_model = bool
  })
}
