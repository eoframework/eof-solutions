#------------------------------------------------------------------------------
# Integrations Module - Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
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

#------------------------------------------------------------------------------
# Storage Integration
#------------------------------------------------------------------------------
variable "storage_account_id" {
  description = "ID of the storage account for event subscriptions"
  type        = string
}

variable "input_container" {
  description = "Name of the input container for blob trigger"
  type        = string
}

#------------------------------------------------------------------------------
# Processing Integration
#------------------------------------------------------------------------------
variable "function_app_id" {
  description = "ID of the Function App"
  type        = string
}

#------------------------------------------------------------------------------
# Database Integration
#------------------------------------------------------------------------------
variable "cosmos_account_id" {
  description = "ID of the Cosmos DB account"
  type        = string
}

#------------------------------------------------------------------------------
# Monitoring Integration
#------------------------------------------------------------------------------
variable "action_group_id" {
  description = "ID of the action group for alerts"
  type        = string
}

variable "enable_alerts" {
  description = "Enable metric alerts"
  type        = bool
  default     = true
}
