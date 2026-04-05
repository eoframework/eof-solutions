#------------------------------------------------------------------------------
# IDP DR Module - Variables
#------------------------------------------------------------------------------
# Consolidated DR module handling both vault (DR region) and replication (source region)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

#------------------------------------------------------------------------------
# Source Resources (passed from storage module)
#------------------------------------------------------------------------------

variable "storage" {
  description = "Storage module outputs for replication source"
  type = object({
    documents_bucket_id   = string
    documents_bucket_arn  = string
    results_table_arn     = string
    jobs_table_arn        = string
  })
}

variable "kms_key_arn" {
  description = "KMS key ARN in source region"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications (optional)"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# DR Configuration (Single grouped variable)
#------------------------------------------------------------------------------

variable "dr" {
  description = "Disaster recovery configuration"
  type = object({
    # Master controls
    vault_enabled       = optional(bool, false)
    replication_enabled = optional(bool, false)
    dr_region           = optional(string)

    # Vault settings (DR region)
    vault_kms_deletion_window_days           = optional(number, 30)
    vault_transition_to_ia_days              = optional(number, 30)
    vault_noncurrent_version_expiration_days = optional(number, 90)
    vault_enable_lock                        = optional(bool, false)

    # Replication settings (source region)
    storage_replication_class       = optional(string, "STANDARD")
    enable_replication_time_control = optional(bool, true)

    # Backup settings
    backup_local_retention_days  = optional(number, 7)
    backup_retention_days        = optional(number, 30)
    enable_weekly_backup         = optional(bool, true)
    weekly_backup_retention_days = optional(number, 90)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
