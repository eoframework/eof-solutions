#------------------------------------------------------------------------------
# IDP API Module - Variables
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
# Lambda Configuration (grouped)
#------------------------------------------------------------------------------

variable "lambda" {
  description = "Lambda configuration including runtime, packages, and source hashes"
  type = object({
    runtime = optional(string, "python3.11")
    packages = object({
      api_upload  = optional(string, "")
      api_status  = optional(string, "")
      api_results = optional(string, "")
      api_list    = optional(string, "")
      api_delete  = optional(string, "")
      api_health  = optional(string, "")
    })
    source_hashes = object({
      api_upload  = optional(string, "")
      api_status  = optional(string, "")
      api_results = optional(string, "")
      api_list    = optional(string, "")
      api_delete  = optional(string, "")
      api_health  = optional(string, "")
    })
  })
}

#------------------------------------------------------------------------------
# VPC Configuration (grouped)
#------------------------------------------------------------------------------

variable "vpc" {
  description = "VPC configuration for Lambda functions"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = {
    subnet_ids         = null
    security_group_ids = []
  }
}

#------------------------------------------------------------------------------
# Storage References
#------------------------------------------------------------------------------

variable "storage" {
  description = "Storage outputs from storage module"
  type = object({
    documents_bucket_name = string
    documents_bucket_id   = string
    documents_bucket_arn  = string
    results_table_name    = string
    results_table_arn     = string
    jobs_table_name       = string
    jobs_table_arn        = string
  })
}

#------------------------------------------------------------------------------
# Step Functions Reference
#------------------------------------------------------------------------------

variable "state_machine_arn" {
  description = "ARN of the document processing Step Functions state machine"
  type        = string
}

#------------------------------------------------------------------------------
# Authentication
#------------------------------------------------------------------------------

variable "cognito_user_pool_arn" {
  description = "Cognito user pool ARN for API authorization (null if auth disabled)"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# API Configuration
#------------------------------------------------------------------------------

variable "api" {
  description = "API Gateway configuration"
  type = object({
    version               = optional(string, "1.0.0")
    stage_name            = optional(string, "v1")
    endpoint_type         = optional(string, "REGIONAL")
    enable_cors           = optional(bool, true)
    max_file_size_mb      = optional(number, 50)
    default_page_size     = optional(number, 20)
    throttling_burst_limit = optional(number, 1000)
    throttling_rate_limit  = optional(number, 500)
    allowed_content_types = optional(list(string), ["application/pdf", "image/png", "image/jpeg", "image/tiff"])
  })
  default = {}
}

#------------------------------------------------------------------------------
# Logging Configuration
#------------------------------------------------------------------------------

variable "logging" {
  description = "Logging configuration"
  type = object({
    retention_days         = optional(number, 30)
    api_gateway_log_level  = optional(string, "INFO")
    data_trace_enabled     = optional(bool, false)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Monitoring Configuration
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring configuration"
  type = object({
    xray_enabled = optional(bool, true)
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
