#------------------------------------------------------------------------------
# Cloud Migration - KMS Module Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Name prefix for the KMS key and alias"
  type        = string
}

variable "description" {
  description = "KMS key description (defaults to 'KMS key for <name_prefix>')"
  type        = string
  default     = ""
}

variable "deletion_window_in_days" {
  description = "Key deletion window in days (7-30)"
  type        = number
  default     = 30
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
