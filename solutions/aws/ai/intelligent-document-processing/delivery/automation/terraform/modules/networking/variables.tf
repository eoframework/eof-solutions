#------------------------------------------------------------------------------
# IDP Networking Module - Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

#------------------------------------------------------------------------------
# VPC Configuration
#------------------------------------------------------------------------------

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr_block           = string
    enable_dns_support   = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    enable_nat_gateway   = optional(bool, false)
    single_nat_gateway   = optional(bool, true)
    enable_flow_logs     = optional(bool, false)
    flow_log_retention_days = optional(number, 30)
  })
}

#------------------------------------------------------------------------------
# Subnet Configuration
#------------------------------------------------------------------------------
# Map key convention: {solution}-{tier}-{availability-zone}
# Example: "idp-private-us-east-1a"
#
# Supported tiers: private
# All IDP subnets are private - Lambda functions do not need public exposure.
# Public subnets are only provisioned when enable_nat_gateway = true (NAT
# gateway requires a public subnet to reach the internet).
#------------------------------------------------------------------------------

variable "subnets" {
  description = "Map of subnet configurations keyed by descriptive name"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    layer = optional(string, "private")
  }))
}

#------------------------------------------------------------------------------
# Security
#------------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "KMS key ARN for flow log CloudWatch log group encryption (optional)"
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
