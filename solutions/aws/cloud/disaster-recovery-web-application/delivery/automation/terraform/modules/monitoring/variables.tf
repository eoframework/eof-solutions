#------------------------------------------------------------------------------
# DR Web Application Monitoring Module - Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "aws" {
  description = "AWS configuration"
  type = object({
    region = string
  })
}

variable "resources" {
  description = "Resource identifiers for monitoring"
  type = object({
    health_check_id         = optional(string, "")
    alb_arn_suffix          = string
    target_group_arn_suffix = string
    asg_name                = string
    aurora_cluster_id       = string
    s3_bucket_id            = optional(string, "")
    s3_dr_bucket_id         = optional(string, "")
  })
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    alert_email                  = optional(string, "")
    rpo_target_ms                = optional(number, 60000)
    alb_5xx_threshold            = optional(number, 10)
    alb_latency_threshold        = optional(number, 2)
    aurora_cpu_threshold         = optional(number, 80)
    aurora_connections_threshold = optional(number, 100)
  })
  default = {}
}

variable "security" {
  description = "Security configuration"
  type = object({
    kms_key_id = string
  })
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
