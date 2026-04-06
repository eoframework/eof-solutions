# AWS Config Rules Module - Variables

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
  description = "KMS key ARN for S3 bucket encryption"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for Config notifications"
  type        = string
  default     = ""
}

variable "config_bucket_name" {
  description = "S3 bucket for Config delivery (created if empty)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Config Rules Configuration (grouped object)
#------------------------------------------------------------------------------

variable "config_rules" {
  description = "AWS Config rules configuration"
  type = object({
    enabled                   = bool
    create_recorder           = optional(bool, true)
    record_all_resources      = optional(bool, true)
    include_global_resources  = optional(bool, true)
    excluded_resource_types   = optional(list(string), [])
    delivery_frequency        = optional(string, "TwentyFour_Hours")
    config_s3_prefix          = optional(string, "config")
    retention_days            = optional(number, 365)
    enable_security_rules     = optional(bool, true)
    enable_reliability_rules  = optional(bool, true)
    enable_operational_rules  = optional(bool, true)
    enable_cost_rules         = optional(bool, true)
    min_backup_retention_days = optional(number, 7)
  })
}
