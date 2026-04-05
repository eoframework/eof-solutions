#------------------------------------------------------------------------------
# Cloud Migration - Security Module Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "security" {
  description = "Security configuration"
  type = object({
    enable_waf     = optional(bool, true)
    waf_rate_limit = optional(number, 2000)
  })
  default = {}
}

variable "network" {
  description = "Network configuration for security groups"
  type = object({
    vpc_id   = string
    app_port = optional(number, 80)
  })
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
