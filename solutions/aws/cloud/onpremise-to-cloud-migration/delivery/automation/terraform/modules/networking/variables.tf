#------------------------------------------------------------------------------
# Cloud Migration - Networking Module Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "network" {
  description = "Network configuration"
  type = object({
    vpc_cidr                = string
    enable_nat_gateway      = optional(bool, true)
    enable_flow_logs        = optional(bool, true)
    enable_site_to_site_vpn = optional(bool, false)
    on_prem_cidr            = optional(string, "")
  })
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting flow logs (null = AWS managed key)"
  type        = string
  default     = null
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
