# AWS Backup Plans Module - Variables

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

variable "kms_key_arn" {
  description = "KMS key ARN for backup vault encryption"
  type        = string
}

variable "dr_kms_key_arn" {
  description = "KMS key ARN for DR region backup vault"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Backup Configuration (grouped object)
#------------------------------------------------------------------------------

variable "backup" {
  description = "AWS Backup configuration"
  type = object({
    enabled                    = bool
    daily_schedule             = optional(string, "cron(0 5 * * ? *)")
    daily_retention            = optional(number, 30)
    enable_continuous          = optional(bool, false)
    enable_weekly              = optional(bool, true)
    weekly_schedule            = optional(string, "cron(0 5 ? * SUN *)")
    weekly_retention           = optional(number, 90)
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
    enable_windows_vss         = optional(bool, false)
    enable_s3_backup           = optional(bool, false)
    enable_vault_policy        = optional(bool, true)
    enable_vault_lock          = optional(bool, false)
    vault_lock_min_retention   = optional(number, 7)
    vault_lock_max_retention   = optional(number, 365)
    vault_lock_changeable_days = optional(number, 3)
    notification_events = optional(list(string), [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_STARTED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ])
  })
}
