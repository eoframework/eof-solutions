#------------------------------------------------------------------------------
# Azure Storage Account Module - Variables
#------------------------------------------------------------------------------

variable "name" {
  description = "Storage account name (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.name))
    error_message = "Storage account name must be 3-24 lowercase letters and numbers only."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the storage account"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.account_tier)
    error_message = "Account tier must be Standard or Premium."
  }
}

variable "replication_type" {
  description = "Replication type (LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS)"
  type        = string
  default     = "LRS"

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "Invalid replication type."
  }
}

variable "account_kind" {
  description = "Storage account kind"
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Access tier for blob storage (Hot or Cool)"
  type        = string
  default     = "Hot"
}

variable "min_tls_version" {
  description = "Minimum TLS version"
  type        = string
  default     = "TLS1_2"
}

variable "allow_public_access" {
  description = "Allow public access to blobs"
  type        = bool
  default     = false
}

variable "shared_access_key_enabled" {
  description = "Enable shared access key authentication"
  type        = bool
  default     = true
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Blob Properties
#------------------------------------------------------------------------------
variable "versioning_enabled" {
  description = "Enable blob versioning"
  type        = bool
  default     = true
}

variable "change_feed_enabled" {
  description = "Enable change feed"
  type        = bool
  default     = false
}

variable "last_access_time_enabled" {
  description = "Enable last access time tracking"
  type        = bool
  default     = false
}

variable "blob_soft_delete_days" {
  description = "Days to retain soft-deleted blobs (0 to disable)"
  type        = number
  default     = 7
}

variable "container_soft_delete_days" {
  description = "Days to retain soft-deleted containers (0 to disable)"
  type        = number
  default     = 7
}

variable "cors_rules" {
  description = "CORS rules for blob storage"
  type = list(object({
    allowed_headers    = list(string)
    allowed_methods    = list(string)
    allowed_origins    = list(string)
    exposed_headers    = list(string)
    max_age_in_seconds = number
  }))
  default = []
}

#------------------------------------------------------------------------------
# Containers
#------------------------------------------------------------------------------
variable "containers" {
  description = "Map of containers to create"
  type = map(object({
    access_type = optional(string, "private")
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Network Rules
#------------------------------------------------------------------------------
variable "enable_network_rules" {
  description = "Enable network rules"
  type        = bool
  default     = false
}

variable "network_default_action" {
  description = "Default action for network rules"
  type        = string
  default     = "Deny"
}

variable "network_bypass" {
  description = "Services to bypass network rules"
  type        = list(string)
  default     = ["AzureServices"]
}

variable "allowed_ip_ranges" {
  description = "IP ranges allowed through network rules"
  type        = list(string)
  default     = []
}

variable "allowed_subnet_ids" {
  description = "Subnet IDs allowed through network rules"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Encryption
#------------------------------------------------------------------------------
variable "customer_managed_key_id" {
  description = "Key Vault key ID for customer-managed encryption"
  type        = string
  default     = null
}

variable "identity_id" {
  description = "User-assigned identity ID for CMK access"
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Identity type (SystemAssigned, UserAssigned, or both)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Lifecycle Rules
#------------------------------------------------------------------------------
variable "lifecycle_rules" {
  description = "Lifecycle management rules. Key is the rule name."
  type = map(object({
    enabled      = optional(bool, true)
    prefix_match = optional(list(string), [])
    blob_types   = optional(list(string), ["blockBlob"])
    base_blob_actions = optional(object({
      tier_to_cool_days    = optional(number)
      tier_to_archive_days = optional(number)
      delete_days          = optional(number)
    }))
    snapshot_actions = optional(object({
      delete_days = optional(number)
    }))
    version_actions = optional(object({
      delete_days = optional(number)
    }))
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
