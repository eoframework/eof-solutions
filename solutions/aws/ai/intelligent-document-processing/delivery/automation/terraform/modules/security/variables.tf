#------------------------------------------------------------------------------
# IDP Security Module - Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

#------------------------------------------------------------------------------
# KMS Configuration
#------------------------------------------------------------------------------

variable "security" {
  description = "Security configuration"
  type = object({
    kms_deletion_window_days = optional(number, 30)
    enable_kms_key_rotation  = optional(bool, true)
  })
  default = {}
}

#------------------------------------------------------------------------------
# VPC Configuration
#------------------------------------------------------------------------------
# Provided by the networking module output. Null when Lambda VPC mode is off.
#------------------------------------------------------------------------------

variable "vpc_id" {
  description = "VPC ID for security group creation (null when VPC mode disabled)"
  type        = string
  default     = null
}

variable "lambda_vpc_enabled" {
  description = "Whether Lambda VPC mode is enabled"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Security Group Configuration
#------------------------------------------------------------------------------
# Map of security groups to create. Key = SG logical name (used in tags and
# cross-SG rule references). Each SG defines separate ingress and egress rule
# maps to allow both CIDR-based and SG-reference rules without circular deps.
#
# Uses aws_vpc_security_group_ingress_rule / aws_vpc_security_group_egress_rule
# (Provider 5+ preferred resources). Key differences from the legacy
# aws_security_group_rule:
#   - ip_protocol instead of protocol
#   - cidr_block (single string) instead of cidr_blocks (list)
#   - referenced_security_group_id instead of source_security_group_id
#   - Tags are supported per-rule
#
# Rule key convention: {direction}_{protocol}_{port}_{source/dest}
# Example: "ingress_tcp_443_lambda", "egress_tcp_443_all"
#------------------------------------------------------------------------------

variable "security_groups" {
  description = "Map of security group configurations"
  type = map(object({
    description = string

    # Rules sourced from a single CIDR block
    ingress_cidr = optional(map(object({
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_block  = string # single CIDR — one resource per CIDR is the new paradigm
      description = optional(string, "")
    })), {})

    egress_cidr = optional(map(object({
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_block  = string
      description = optional(string, "")
    })), {})

    # Rules sourced from another SG in this same security_groups map
    ingress_sg = optional(map(object({
      from_port                 = number
      to_port                   = number
      ip_protocol               = string
      source_security_group_key = string # must match a key in security_groups
      description               = optional(string, "")
    })), {})

    egress_sg = optional(map(object({
      from_port                 = number
      to_port                   = number
      ip_protocol               = string
      source_security_group_key = string
      description               = optional(string, "")
    })), {})
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
