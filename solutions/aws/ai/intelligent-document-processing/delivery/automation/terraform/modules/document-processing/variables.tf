#------------------------------------------------------------------------------
# IDP Document Processing Module - Variables
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
      start_analysis      = optional(string, "")
      process_textract    = optional(string, "")
      comprehend_analysis = optional(string, "")
      validate_document   = optional(string, "")
      finalize_results    = optional(string, "")
    })
    source_hashes = object({
      start_analysis      = optional(string, "")
      process_textract    = optional(string, "")
      comprehend_analysis = optional(string, "")
      validate_document   = optional(string, "")
      finalize_results    = optional(string, "")
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
# Human Review References (optional - can be wired after creation)
#------------------------------------------------------------------------------

variable "human_review" {
  description = "Human review queue outputs (null if disabled, can be passed after human_review module creation)"
  type = object({
    queue_url = string
    queue_arn = string
  })
  default = null
}

#------------------------------------------------------------------------------
# AI Services Configuration (grouped)
#------------------------------------------------------------------------------

variable "ai_services" {
  description = "AI services configuration (Textract and Comprehend)"
  type = object({
    textract = optional(object({
      supported_document_types = optional(list(string), ["pdf", "png", "jpg", "jpeg", "tiff"])
      max_file_size_mb         = optional(number, 50)
      confidence_threshold     = optional(number, 80)
      polling_interval_seconds = optional(number, 30)
      max_polling_attempts     = optional(number, 20)
      enable_tables            = optional(bool, true)
      enable_forms             = optional(bool, true)
      enable_queries           = optional(bool, false)
      enable_signatures        = optional(bool, false)
      enable_expense           = optional(bool, false)
      enable_id                = optional(bool, false)
    }), {})
    comprehend = optional(object({
      enable_pii_detection    = optional(bool, true)
      enable_entity_detection = optional(bool, true)
      enable_key_phrases      = optional(bool, true)
      enable_sentiment        = optional(bool, false)
      language_code           = optional(string, "en")
      pii_entity_types        = optional(list(string), ["ALL"])
    }), {})
  })
  default = {}
}

#------------------------------------------------------------------------------
# Logging Configuration
#------------------------------------------------------------------------------

variable "logging" {
  description = "Logging configuration"
  type = object({
    retention_days           = optional(number, 30)
    step_functions_log_level = optional(string, "ERROR")
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
