#------------------------------------------------------------------------------
# Secrets Module - Variables
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Naming Configuration
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Name prefix for all secrets (e.g., idp-prod, idp-test)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# Feature Flags
#------------------------------------------------------------------------------

variable "create_kms_key" {
  description = "Create dedicated KMS key for secrets (otherwise uses AWS managed key)"
  type        = bool
  default     = true
}

variable "create_api_key_secret" {
  description = "Create an API key secret for external service integrations"
  type        = bool
  default     = true
}

variable "create_workteam_secret" {
  description = "Create a secret to store SageMaker A2I workteam credentials"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# Secret Name Suffixes
#------------------------------------------------------------------------------

variable "api_key_secret_suffix" {
  description = "Suffix for the API key secret name"
  type        = string
  default     = "api-key"
}

variable "workteam_secret_suffix" {
  description = "Suffix for the workteam credentials secret name"
  type        = string
  default     = "workteam-credentials"
}

#------------------------------------------------------------------------------
# Secret Configuration
#------------------------------------------------------------------------------

variable "secret_recovery_window" {
  description = "Number of days before a secret can be deleted (0 for immediate)"
  type        = number
  default     = 7

  validation {
    condition     = var.secret_recovery_window >= 0 && var.secret_recovery_window <= 30
    error_message = "Recovery window must be between 0 and 30 days."
  }
}
