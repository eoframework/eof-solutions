#------------------------------------------------------------------------------
# Monitoring Module - Variables
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

variable "function_app_id" {
  description = "ID of the Function App"
  type        = string
}

variable "cosmos_account_name" {
  description = "Name of the Cosmos DB account"
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account"
  type        = string
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    enable_alerts         = bool
    enable_dashboard      = bool
    log_retention_days    = number
    alert_email           = string
    health_check_interval = number
  })
}
