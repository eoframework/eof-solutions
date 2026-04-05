#------------------------------------------------------------------------------
# Best Practices Module - Variables
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Common Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "environment" {
  description = "Environment name (prod, test, dr)"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
}

#------------------------------------------------------------------------------
# Optional Bucket Names (auto-generated if empty)
#------------------------------------------------------------------------------

variable "config_bucket_name" {
  description = "S3 bucket for AWS Config (auto-generated if empty)"
  type        = string
  default     = ""
}

variable "guardduty_findings_bucket" {
  description = "S3 bucket for GuardDuty findings (auto-generated if empty)"
  type        = string
  default     = ""
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for DR region backup vault"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Config Rules Configuration
#------------------------------------------------------------------------------

variable "config_rules" {
  description = "AWS Config rules configuration"
  type = object({
    enabled                   = bool
    enable_recorder           = bool
    retention_days            = number
    # Rule Categories
    enable_security_rules     = optional(bool, true)
    enable_reliability_rules  = optional(bool, true)
    enable_operational_rules  = optional(bool, true)
    enable_cost_rules         = optional(bool, true)
    # Rule Parameters
    min_backup_retention_days = optional(number, 7)
    # Config Recorder Settings
    record_all_resources      = optional(bool, true)
    include_global_resources  = optional(bool, true)
    excluded_resource_types   = optional(list(string), [])
    delivery_frequency        = optional(string, "TwentyFour_Hours")
  })
}

#------------------------------------------------------------------------------
# GuardDuty Enhanced Configuration
#------------------------------------------------------------------------------

variable "guardduty_enhanced" {
  description = "Enhanced GuardDuty configuration"
  type = object({
    enabled                   = bool
    enable_eks_protection     = optional(bool, false)
    enable_malware_protection = optional(bool, true)
    severity_threshold        = optional(number, 7)
    enable_s3_export          = optional(bool, true)
    findings_retention_days   = optional(number, 365)
  })
}

#------------------------------------------------------------------------------
# Backup Configuration
#------------------------------------------------------------------------------

variable "backup" {
  description = "AWS Backup configuration"
  type = object({
    enabled                    = optional(bool, false)
    daily_schedule             = optional(string, "cron(0 5 * * ? *)")
    daily_retention            = optional(number, 7)
    enable_weekly              = optional(bool, true)
    weekly_schedule            = optional(string, "cron(0 5 ? * SUN *)")
    weekly_retention           = optional(number, 30)
    enable_monthly             = optional(bool, true)
    monthly_schedule           = optional(string, "cron(0 5 1 * ? *)")
    monthly_retention          = optional(number, 365)
    cold_storage_days          = optional(number, 90)
    enable_cross_region        = optional(bool, false)
    dr_retention               = optional(number, 30)
    enable_tag_selection       = optional(bool, true)
    backup_tag_key             = optional(string, "Backup")
    backup_tag_value           = optional(string, "true")
    resource_arns              = optional(list(string), [])
    enable_continuous          = optional(bool, false)
    enable_windows_vss         = optional(bool, false)
    enable_s3_backup           = optional(bool, false)
    enable_vault_policy        = optional(bool, true)
    enable_vault_lock          = optional(bool, false)
    vault_lock_min_retention   = optional(number, 7)
    vault_lock_max_retention   = optional(number, 365)
    vault_lock_changeable_days = optional(number, 3)
    notification_events        = optional(list(string), [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ])
  })
  default = { enabled = false }
}

#------------------------------------------------------------------------------
# Budget Configuration
#------------------------------------------------------------------------------

variable "budget" {
  description = "AWS Budgets configuration"
  type = object({
    enabled                      = bool
    monthly_amount               = number
    alert_thresholds             = list(number)
    enable_forecast_alert        = optional(bool, true)
    forecast_threshold           = optional(number, 100)
    alert_emails                 = optional(list(string), [])
    # Optional advanced settings with defaults
    enable_cost_budget           = optional(bool, true)
    budget_currency              = optional(string, "USD")
    budget_time_unit             = optional(string, "MONTHLY")
    notification_comparison      = optional(string, "GREATER_THAN")
    notification_threshold_type  = optional(string, "PERCENTAGE")
    notification_type            = optional(string, "ACTUAL")
    enable_service_budgets       = optional(bool, false)
    ec2_budget_amount            = optional(number, 0)
    rds_budget_amount            = optional(number, 0)
    data_transfer_budget_amount  = optional(number, 0)
    service_alert_threshold      = optional(number, 80)
    enable_usage_budget          = optional(bool, false)
    ec2_usage_hours_limit        = optional(number, 0)
    enable_actions               = optional(bool, false)
    action_approval              = optional(string, "AUTOMATIC")
    action_threshold             = optional(number, 100)
    ec2_instances_to_stop        = optional(list(string), [])
  })
}
