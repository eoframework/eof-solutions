#------------------------------------------------------------------------------
# Storage Module - Variables
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

variable "subnet_id" {
  description = "Subnet ID for private endpoints (null if disabled)"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "ID of the Key Vault for storing secrets"
  type        = string
}

variable "storage" {
  description = "Blob storage configuration"
  type = object({
    account_tier         = string
    replication_type     = string
    input_container      = string
    processed_container  = string
    failed_container     = string
    archive_container    = string
    retention_hot_days   = number
    retention_cool_days  = number
    retention_total_days = number
  })
}

variable "database" {
  description = "Cosmos DB configuration"
  type = object({
    cosmos_offer_type             = string
    cosmos_consistency_level      = string
    cosmos_database_name          = string
    cosmos_metadata_container     = string
    cosmos_results_container      = string
    cosmos_max_throughput         = number
    cosmos_enable_free_tier       = bool
    cosmos_backup_type            = string
    cosmos_backup_interval_hours  = number
    cosmos_backup_retention_hours = number
  })
}
