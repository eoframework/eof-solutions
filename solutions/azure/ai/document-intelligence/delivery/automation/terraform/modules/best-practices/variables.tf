#------------------------------------------------------------------------------
# Best Practices Module - Variables
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

variable "action_group_id" {
  description = "ID of the action group for alerts"
  type        = string
}

variable "backup" {
  description = "Backup configuration"
  type = object({
    enabled        = bool
    retention_days = number
  })
}

variable "budget" {
  description = "Budget configuration"
  type = object({
    enabled            = bool
    monthly_amount     = number
    alert_thresholds   = map(number) # e.g. { warning = 50, critical = 80, maximum = 100 }
    notification_email = string
  })
}

variable "policy" {
  description = "Azure Policy configuration"
  type = object({
    enable_security_policies    = bool
    enable_cost_policies        = bool
    enable_operational_policies = bool
  })
}
