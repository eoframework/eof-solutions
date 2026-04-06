# AWS Budgets Module - Variables

#------------------------------------------------------------------------------
# Naming & Tags
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (for budget action conditions)"
  type        = string
  default     = "prod"
}

variable "sns_topic_arns" {
  description = "SNS topic ARNs for budget alerts"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Budget Configuration (grouped object)
#------------------------------------------------------------------------------

variable "budget" {
  description = "AWS Budgets configuration"
  type = object({
    enabled                     = bool
    enable_cost_budget          = optional(bool, true)
    monthly_amount              = optional(number, 1000)
    alert_thresholds            = optional(list(number), [50, 80, 100])
    enable_forecast_alert       = optional(bool, true)
    forecast_threshold          = optional(number, 100)
    alert_emails                = optional(list(string), [])
    linked_account_ids          = optional(list(string), null)
    cost_filter_tags            = optional(map(string), null)
    cost_filter_services        = optional(list(string), null)
    enable_service_budgets      = optional(bool, false)
    ec2_budget_amount           = optional(number, 0)
    rds_budget_amount           = optional(number, 0)
    data_transfer_budget_amount = optional(number, 0)
    enable_usage_budget         = optional(bool, false)
    ec2_usage_hours_limit       = optional(number, 1000)
    enable_actions              = optional(bool, false)
    action_approval             = optional(string, "MANUAL")
    action_threshold            = optional(number, 100)
    ec2_instances_to_stop       = optional(list(string), [])
  })
}
