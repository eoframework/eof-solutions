#------------------------------------------------------------------------------
# AWS Lambda Function Module - Variables
#------------------------------------------------------------------------------

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = ""
}

variable "handler" {
  description = "Function entrypoint (e.g., index.handler)"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.11, nodejs18.x)"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Function memory in MB"
  type        = number
  default     = 256
}

#------------------------------------------------------------------------------
# Code Source
#------------------------------------------------------------------------------

variable "s3_bucket" {
  description = "S3 bucket containing the function code"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key for the function code"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 object version for the function code"
  type        = string
  default     = null
}

variable "filename" {
  description = "Path to local zip file containing function code"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "Hash of the source code for change detection"
  type        = string
  default     = null
}

variable "layers" {
  description = "List of Lambda layer ARNs"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

variable "environment_variables" {
  description = "Environment variables for the function"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# VPC Configuration
#------------------------------------------------------------------------------

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for VPC configuration"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for VPC configuration"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Concurrency & Performance
#------------------------------------------------------------------------------

variable "reserved_concurrent_executions" {
  description = "Reserved concurrent executions (-1 for unreserved)"
  type        = number
  default     = -1
}

variable "provisioned_concurrent_executions" {
  description = "Provisioned concurrency (0 to disable)"
  type        = number
  default     = 0
}

variable "tracing_mode" {
  description = "X-Ray tracing mode (Active or PassThrough)"
  type        = string
  default     = "Active"
}

#------------------------------------------------------------------------------
# Dead Letter Queue
#------------------------------------------------------------------------------

variable "dead_letter_target_arn" {
  description = "ARN of SQS queue or SNS topic for failed invocations"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Encryption
#------------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting environment variables"
  type        = string
  default     = null
}

#------------------------------------------------------------------------------
# Architecture
#------------------------------------------------------------------------------

variable "architectures" {
  description = "Instruction set architecture (x86_64 or arm64). arm64 (Graviton2) is 20% cheaper per GB-second."
  type        = list(string)
  default     = ["arm64"]

  validation {
    condition     = length(var.architectures) == 1 && contains(["x86_64", "arm64"], var.architectures[0])
    error_message = "architectures must be a single-element list containing either x86_64 or arm64."
  }
}

#------------------------------------------------------------------------------
# Logging
#------------------------------------------------------------------------------

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "log_format" {
  description = "CloudWatch log format (Text or JSON). JSON enables structured logging and CloudWatch Insights queries."
  type        = string
  default     = "JSON"

  validation {
    condition     = contains(["Text", "JSON"], var.log_format)
    error_message = "log_format must be Text or JSON."
  }
}

variable "log_level" {
  description = "Log level filter applied when log_format is JSON (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], var.log_level)
    error_message = "log_level must be one of TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  }
}

#------------------------------------------------------------------------------
# Permissions (for triggers)
#------------------------------------------------------------------------------

variable "permissions" {
  description = "Map of Lambda permissions for triggers"
  type = map(object({
    principal  = string
    source_arn = string
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Event Source Mappings
#------------------------------------------------------------------------------

variable "event_source_mappings" {
  description = "Map of event source mappings (SQS, DynamoDB Streams)"
  type = map(object({
    event_source_arn  = string
    starting_position = optional(string)
    batch_size        = optional(number)
    enabled           = optional(bool)
    filter_pattern    = optional(string)
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
