#------------------------------------------------------------------------------
# Cloud Migration - Compute Module Variables
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
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
}

variable "compute" {
  description = "Compute configuration"
  type = object({
    instance_type              = optional(string, "m5.large")
    ami_id                     = optional(string, "")
    asg_min_size               = optional(number, 2)
    asg_max_size               = optional(number, 20)
    asg_desired_capacity       = optional(number, 4)
    root_volume_size           = optional(number, 50)
    data_volume_size           = optional(number, 0)
    app_port                   = optional(number, 443)
    health_check_path          = optional(string, "/health")
    ssl_certificate_arn        = optional(string, "")
    instance_profile_arn       = optional(string, "")
    user_data_base64           = optional(string, "")
    enable_deletion_protection = optional(bool, true)
  })
  default = {}
}

variable "security" {
  description = "Security configuration from security module"
  type = object({
    alb_security_group_id = string
    app_security_group_id = string
    kms_key_arn           = string
  })
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
