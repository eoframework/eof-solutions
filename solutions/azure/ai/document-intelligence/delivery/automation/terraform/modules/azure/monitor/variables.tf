#------------------------------------------------------------------------------
# Azure Monitor Module - Variables
#------------------------------------------------------------------------------

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

#------------------------------------------------------------------------------
# Log Analytics
#------------------------------------------------------------------------------
variable "create_log_analytics" {
  description = "Create Log Analytics workspace"
  type        = bool
  default     = true
}

variable "log_analytics_name" {
  description = "Log Analytics workspace name"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Existing Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "log_analytics_sku" {
  description = "Log Analytics SKU"
  type        = string
  default     = "PerGB2018"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "daily_quota_gb" {
  description = "Daily quota in GB (-1 for no limit)"
  type        = number
  default     = -1
}

variable "internet_ingestion_enabled" {
  description = "Enable internet ingestion"
  type        = bool
  default     = true
}

variable "internet_query_enabled" {
  description = "Enable internet query"
  type        = bool
  default     = true
}

variable "reservation_capacity_gb" {
  description = "Reservation capacity in GB"
  type        = number
  default     = null
}

#------------------------------------------------------------------------------
# Application Insights
#------------------------------------------------------------------------------
variable "create_app_insights" {
  description = "Create Application Insights"
  type        = bool
  default     = true
}

variable "app_insights_name" {
  description = "Application Insights name"
  type        = string
  default     = null
}

variable "application_type" {
  description = "Application type"
  type        = string
  default     = "web"
}

variable "app_insights_retention_days" {
  description = "App Insights retention days"
  type        = number
  default     = 90
}

variable "daily_data_cap_gb" {
  description = "Daily data cap in GB"
  type        = number
  default     = null
}

variable "daily_data_cap_notifications_disabled" {
  description = "Disable daily cap notifications"
  type        = bool
  default     = false
}

variable "sampling_percentage" {
  description = "Sampling percentage"
  type        = number
  default     = 100
}

variable "disable_ip_masking" {
  description = "Disable IP masking"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Disable local authentication"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Action Group
#------------------------------------------------------------------------------
variable "create_action_group" {
  description = "Create action group"
  type        = bool
  default     = true
}

variable "action_group_name" {
  description = "Action group name"
  type        = string
  default     = null
}

variable "action_group_short_name" {
  description = "Action group short name (max 12 chars)"
  type        = string
  default     = "alerts"
}

variable "action_group_enabled" {
  description = "Enable action group"
  type        = bool
  default     = true
}

variable "email_receivers" {
  description = "Email receivers. Key is the receiver name."
  type = map(object({
    email_address           = string
    use_common_alert_schema = optional(bool, true)
  }))
  default = {}
}

variable "sms_receivers" {
  description = "SMS receivers. Key is the receiver name."
  type = map(object({
    country_code = string
    phone_number = string
  }))
  default = {}
}

variable "webhook_receivers" {
  description = "Webhook receivers. Key is the receiver name."
  type = map(object({
    service_uri             = string
    use_common_alert_schema = optional(bool, true)
  }))
  default = {}
}

variable "azure_function_receivers" {
  description = "Azure Function receivers. Key is the receiver name."
  type = map(object({
    function_app_resource_id = string
    function_name            = string
    http_trigger_url         = string
    use_common_alert_schema  = optional(bool, true)
  }))
  default = {}
}

variable "logic_app_receivers" {
  description = "Logic App receivers. Key is the receiver name."
  type = map(object({
    resource_id             = string
    callback_url            = string
    use_common_alert_schema = optional(bool, true)
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Diagnostic Settings
#------------------------------------------------------------------------------
variable "diagnostic_settings" {
  description = "Diagnostic settings to create"
  type = map(object({
    target_resource_id             = string
    storage_account_id             = optional(string)
    eventhub_authorization_rule_id = optional(string)
    eventhub_name                  = optional(string)
    log_categories                 = optional(list(string), [])
    metric_categories              = optional(list(string), [])
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Dashboard
#------------------------------------------------------------------------------
variable "create_dashboard" {
  description = "Create dashboard"
  type        = bool
  default     = false
}

variable "dashboard_name" {
  description = "Dashboard name"
  type        = string
  default     = null
}

variable "dashboard_properties" {
  description = "Dashboard properties JSON"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------
variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
