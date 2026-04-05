#------------------------------------------------------------------------------
# DR Web Application - Disaster Recovery Module Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "dr" {
  description = "DR configuration"
  type = object({
    enabled                               = optional(bool, true)
    vault_enabled                         = optional(bool, true)
    replication_enabled                   = optional(bool, true)
    kms_deletion_window_days              = optional(number, 30)
    vault_transition_to_ia_days           = optional(number, 30)
    vault_noncurrent_version_expiration_days = optional(number, 30)
    backup_retention_days                 = optional(number, 30)
    dr_backup_retention_days              = optional(number, 90)
    enable_weekly_backup                  = optional(bool, true)
    weekly_backup_retention_days          = optional(number, 90)
    enable_continuous_backup              = optional(bool, false)
    replication_lag_threshold_ms          = optional(number, 60000)
  })
  default = {}
}

variable "dns" {
  description = "DNS configuration"
  type = object({
    hosted_zone_id                = optional(string, "")
    domain_name                   = optional(string, "")
    health_check_path             = optional(string, "/health")
    health_check_interval         = optional(number, 30)
    health_check_failure_threshold = optional(number, 3)
  })
  default = {}
}

variable "primary" {
  description = "Primary region resources"
  type = object({
    alb_dns_name      = string
    alb_zone_id       = string
    aurora_cluster_id = optional(string, "")
  })
}

variable "dr_alb" {
  description = "DR region ALB (if exists)"
  type = object({
    dns_name = optional(string, "")
    zone_id  = optional(string, "")
  })
  default = {}
}

variable "security" {
  description = "Security configuration"
  type = object({
    kms_key_arn = string
  })
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    sns_topic_arn = optional(string, "")
  })
  default = {}
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
