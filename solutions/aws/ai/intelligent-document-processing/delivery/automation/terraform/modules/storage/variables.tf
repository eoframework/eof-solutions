#------------------------------------------------------------------------------
# IDP Storage Module - Variables
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

variable "aws_account_id" {
  description = "AWS account ID for unique bucket naming"
  type        = string
}

#------------------------------------------------------------------------------
# S3 Storage Configuration
#------------------------------------------------------------------------------

variable "storage" {
  description = "S3 storage configuration"
  type = object({
    # General settings
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)

    # Lifecycle transitions
    transition_to_ia_days               = optional(number, 30)
    transition_to_glacier_days          = optional(number, 90)
    document_expiration_days            = optional(number, 365)
    noncurrent_version_expiration_days  = optional(number, 30)

    # Direct upload settings
    enable_direct_upload   = optional(bool, true)
    cors_allowed_origins   = optional(list(string), ["*"])

    # Output bucket
    create_output_bucket   = optional(bool, true)
    output_expiration_days = optional(number, 30)
  })
  default = {}
}

#------------------------------------------------------------------------------
# DynamoDB Configuration
#------------------------------------------------------------------------------

variable "database" {
  description = "DynamoDB configuration"
  type = object({
    # Capacity mode
    billing_mode   = optional(string, "PAY_PER_REQUEST")
    read_capacity  = optional(number, 5)
    write_capacity = optional(number, 5)
    gsi_read_capacity  = optional(number, 5)
    gsi_write_capacity = optional(number, 5)

    # Features
    ttl_enabled              = optional(bool, true)
    point_in_time_recovery   = optional(bool, true)
    stream_enabled           = optional(bool, false)
    stream_view_type         = optional(string, "NEW_AND_OLD_IMAGES")

    # Auto-scaling (PROVISIONED mode only)
    enable_autoscaling             = optional(bool, true)
    autoscaling_min_read           = optional(number, 5)
    autoscaling_max_read           = optional(number, 100)
    autoscaling_min_write          = optional(number, 5)
    autoscaling_max_write          = optional(number, 100)
    autoscaling_target_utilization = optional(number, 70)
  })
  default = {}
}


#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
