#------------------------------------------------------------------------------
# Cloud Migration - Monitoring Module Variables
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
    alb_arn_suffix          = string
    target_group_arn_suffix = string
    asg_name                = string
    rds_instance_id         = string
    s3_bucket_id            = optional(string, "")
  })
}

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    alert_email               = optional(string, "")
    ec2_cpu_threshold         = optional(number, 80)
    rds_cpu_threshold         = optional(number, 80)
    rds_connections_threshold = optional(number, 200)
    alb_5xx_threshold         = optional(number, 10)
    log_retention_days        = optional(number, 90)
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
