#------------------------------------------------------------------------------
# IDP Human Review Module - Variables
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
      process_review = optional(string, "")
      create_task    = optional(string, "")
      complete_task  = optional(string, "")
    })
    source_hashes = object({
      process_review = optional(string, "")
      create_task    = optional(string, "")
      complete_task  = optional(string, "")
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
# Step Functions Reference (optional - can be wired after creation)
#------------------------------------------------------------------------------

variable "step_functions_arn" {
  description = "ARN of the document processing Step Functions state machine (optional)"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# SQS Queue Configuration
#------------------------------------------------------------------------------

variable "queue" {
  description = "SQS queue configuration"
  type = object({
    visibility_timeout = optional(number, 300)
    message_retention  = optional(number, 1209600)
    receive_wait_time  = optional(number, 10)
    max_receive_count  = optional(number, 3)
  })
  default = {}
}

#------------------------------------------------------------------------------
# A2I Configuration
#------------------------------------------------------------------------------

variable "a2i" {
  description = "Amazon A2I configuration"
  type = object({
    enabled                   = optional(bool, false)
    use_private_workforce     = optional(bool, true)
    workteam_arn              = optional(string)
    task_price_usd            = optional(number, 0.05)
    task_title                = optional(string, "Document Review Task")
    task_description          = optional(string, "Review the extracted document data and verify accuracy")
    task_count                = optional(number, 1)
    task_availability_seconds = optional(number, 43200)
    confidence_threshold      = optional(number, 80)
    custom_ui_template        = optional(string)
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
