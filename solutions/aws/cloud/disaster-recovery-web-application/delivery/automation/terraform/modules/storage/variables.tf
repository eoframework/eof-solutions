#------------------------------------------------------------------------------
# DR Web Application Storage Module - Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "storage" {
  description = "Storage configuration"
  type = object({
    enable_versioning                  = optional(bool, true)
    transition_to_ia_days              = optional(number, 30)
    transition_to_glacier_days         = optional(number, 90)
    noncurrent_version_expiration_days = optional(number, 30)
    enable_replication                 = optional(bool, false)
    dr_bucket_arn                      = optional(string, "")
    dr_kms_key_arn                     = optional(string, "")
    dr_region                          = optional(string, "us-west-2")
    replication_storage_class          = optional(string, "STANDARD")
    enable_replication_time_control    = optional(bool, true)
    replication_latency_threshold      = optional(number, 900)
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
