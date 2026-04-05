#------------------------------------------------------------------------------
# IDP Monitoring Module - Variables
#------------------------------------------------------------------------------
# Centralized monitoring for IDP solution including CloudWatch alarms
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
# Resources to Monitor
#------------------------------------------------------------------------------

variable "resources" {
  description = "Resource identifiers to monitor"
  type = object({
    api_id            = string
    api_stage         = string
    state_machine_arn = string
    lambda_arns       = optional(map(string), {})
  })
}

#------------------------------------------------------------------------------
# Monitoring Configuration (Single grouped variable)
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring and alerting configuration"
  type = object({
    enabled       = optional(bool, true)
    sns_topic_arn = optional(string)

    # API Gateway thresholds
    api_error_threshold = optional(number, 10)
    api_4xx_threshold   = optional(number, 100)
    api_latency_p95_ms  = optional(number, 2000)

    # Step Functions thresholds
    sfn_failure_threshold = optional(number, 5)

    # Lambda thresholds
    lambda_error_rate_percent = optional(number, 5)
    lambda_duration_p95_ms    = optional(number, 60000)
  })
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
