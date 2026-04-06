#------------------------------------------------------------------------------
# Azure Cosmos DB Module - Variables
#------------------------------------------------------------------------------

variable "name" {
  description = "Cosmos DB account name"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
}

variable "kind" {
  description = "Cosmos DB account kind (GlobalDocumentDB, MongoDB, Parse)"
  type        = string
  default     = "GlobalDocumentDB"
}

#------------------------------------------------------------------------------
# Consistency
#------------------------------------------------------------------------------
variable "consistency_level" {
  description = "Consistency level (BoundedStaleness, Eventual, Session, Strong, ConsistentPrefix)"
  type        = string
  default     = "Session"
}

variable "max_interval_in_seconds" {
  description = "Max interval for BoundedStaleness consistency"
  type        = number
  default     = 5
}

variable "max_staleness_prefix" {
  description = "Max staleness prefix for BoundedStaleness consistency"
  type        = number
  default     = 100
}

#------------------------------------------------------------------------------
# Geo-Locations
#------------------------------------------------------------------------------
variable "geo_locations" {
  description = "Map of geo-locations for replication. Key is a logical name (e.g. 'primary', 'secondary')."
  type = map(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
}

#------------------------------------------------------------------------------
# Capabilities
#------------------------------------------------------------------------------
variable "capabilities" {
  description = "List of Cosmos DB capabilities"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Backup
#------------------------------------------------------------------------------
variable "backup_type" {
  description = "Backup type (Continuous or Periodic)"
  type        = string
  default     = "Periodic"
}

variable "backup_interval_minutes" {
  description = "Backup interval in minutes (for Periodic)"
  type        = number
  default     = 240
}

variable "backup_retention_hours" {
  description = "Backup retention in hours (for Periodic)"
  type        = number
  default     = 8
}

variable "backup_storage_redundancy" {
  description = "Backup storage redundancy (Geo, Local, Zone)"
  type        = string
  default     = "Geo"
}

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
variable "enable_virtual_network_filter" {
  description = "Enable virtual network filtering"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = true
}

variable "ip_range_filter" {
  description = "IP range filter (comma-separated CIDRs)"
  type        = string
  default     = null
}

variable "virtual_network_rules" {
  description = "Virtual network rules"
  type = list(object({
    subnet_id               = string
    ignore_missing_endpoint = optional(bool, false)
  }))
  default = []
}

#------------------------------------------------------------------------------
# Encryption
#------------------------------------------------------------------------------
variable "key_vault_key_id" {
  description = "Key Vault key ID for CMK encryption"
  type        = string
  default     = null
}

variable "identity_type" {
  description = "Identity type (SystemAssigned, UserAssigned)"
  type        = string
  default     = null
}

variable "identity_ids" {
  description = "User-assigned identity IDs"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Performance
#------------------------------------------------------------------------------
variable "automatic_failover_enabled" {
  description = "Enable automatic failover"
  type        = bool
  default     = true
}

variable "multiple_write_locations_enabled" {
  description = "Enable multi-region writes"
  type        = bool
  default     = false
}

variable "free_tier_enabled" {
  description = "Enable free tier (one per subscription)"
  type        = bool
  default     = false
}

variable "analytical_storage_enabled" {
  description = "Enable analytical storage"
  type        = bool
  default     = false
}

variable "local_authentication_disabled" {
  description = "Disable local authentication (key-based)"
  type        = bool
  default     = false
}

#------------------------------------------------------------------------------
# SQL Databases
#------------------------------------------------------------------------------
variable "sql_databases" {
  description = "Map of SQL databases to create"
  type = map(object({
    throughput     = optional(number)
    max_throughput = optional(number)
  }))
  default = {}
}

#------------------------------------------------------------------------------
# SQL Containers
#------------------------------------------------------------------------------
variable "sql_containers" {
  description = "Map of SQL containers to create"
  type = map(object({
    database_name         = string
    partition_key_path    = string
    partition_key_version = optional(number, 1)
    throughput            = optional(number)
    max_throughput        = optional(number)
    default_ttl           = optional(number)
    indexing_policy = optional(object({
      indexing_mode  = optional(string, "consistent")
      included_paths = optional(list(string), ["/*"])
      excluded_paths = optional(list(string), [])
    }))
    unique_keys = optional(list(object({
      paths = list(string)
    })), [])
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Tags
#------------------------------------------------------------------------------
variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
