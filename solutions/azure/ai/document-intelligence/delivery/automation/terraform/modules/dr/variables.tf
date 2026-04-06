#------------------------------------------------------------------------------
# Disaster Recovery Module - Variables
#------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Primary Azure region"
  type        = string
}

variable "dr_location" {
  description = "DR Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the primary resource group"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}

variable "source_storage_account_id" {
  description = "ID of the source storage account for replication"
  type        = string
}

variable "source_cosmos_account_name" {
  description = "Name of the source Cosmos DB account"
  type        = string
}

variable "storage_containers" {
  description = "Container names from the primary storage module — used for replication rules"
  type = object({
    input_container     = string
    processed_container = string
  })
}

variable "dr" {
  description = "DR configuration"
  type = object({
    enabled             = bool
    replication_enabled = bool
    failover_priority   = number
  })
}
