# AWS GuardDuty Module - Variables

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
  description = "KMS key ARN for encrypting findings"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  type        = string
  default     = ""
}

variable "findings_bucket_arn" {
  description = "S3 bucket ARN for findings (created if empty)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# GuardDuty Configuration (grouped object)
#------------------------------------------------------------------------------

variable "guardduty" {
  description = "GuardDuty configuration"
  type = object({
    enabled                      = bool
    finding_publishing_frequency = optional(string, "FIFTEEN_MINUTES")
    enable_s3_protection         = optional(bool, true)
    enable_eks_protection        = optional(bool, false)
    enable_malware_protection    = optional(bool, true)
    enable_s3_export             = optional(bool, true)
    findings_retention_days      = optional(number, 365)
    enable_alerts                = optional(bool, true)
    alert_severity_threshold     = optional(number, 7)
    trusted_ip_list_bucket       = optional(string, "")
    trusted_ip_list_key          = optional(string, "")
    threat_intel_list_bucket     = optional(string, "")
    threat_intel_list_key        = optional(string, "")
  })
}
