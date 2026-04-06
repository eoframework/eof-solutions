#------------------------------------------------------------------------------
# Storage Module
# Creates: Storage Account, Blob Containers, Cosmos DB Account, Database, Containers
# Uses: modules/azure/storage-account, modules/azure/cosmos-db
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Random suffix for globally unique names
#------------------------------------------------------------------------------
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

#------------------------------------------------------------------------------
# Storage Account (via Azure module)
#------------------------------------------------------------------------------
module "storage_account" {
  source = "../../azure/storage-account"

  name                = "${replace(var.name_prefix, "-", "")}st${random_string.storage_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  account_tier        = var.storage.account_tier
  replication_type    = var.storage.replication_type

  # Blob containers
  containers = {
    (var.storage.input_container)     = { access_type = "private" }
    (var.storage.processed_container) = { access_type = "private" }
    (var.storage.failed_container)    = { access_type = "private" }
    (var.storage.archive_container)   = { access_type = "private" }
  }

  # Lifecycle policy
  lifecycle_rules = {
    archive-policy = {
      enabled      = true
      blob_types   = ["blockBlob"]
      prefix_match = ["${var.storage.processed_container}/"]
      base_blob_actions = {
        tier_to_cool_days    = var.storage.retention_hot_days
        tier_to_archive_days = var.storage.retention_hot_days + var.storage.retention_cool_days
        delete_days          = var.storage.retention_total_days
      }
    }
  }

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Cosmos DB (via Azure module)
#------------------------------------------------------------------------------
module "cosmos_db" {
  source = "../../azure/cosmos-db"

  name                = "${var.name_prefix}-cosmos"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "GlobalDocumentDB"

  automatic_failover_enabled = true
  free_tier_enabled          = var.database.cosmos_enable_free_tier
  consistency_level         = var.database.cosmos_consistency_level

  geo_locations = {
    primary = {
      location          = var.location
      failover_priority = 0
    }
  }

  backup_type             = var.database.cosmos_backup_type
  backup_interval_minutes = var.database.cosmos_backup_interval_hours * 60
  backup_retention_hours  = var.database.cosmos_backup_retention_hours

  # SQL Databases
  sql_databases = {
    (var.database.cosmos_database_name) = {}
  }

  # SQL Containers
  sql_containers = {
    (var.database.cosmos_metadata_container) = {
      database_name      = var.database.cosmos_database_name
      partition_key_path = "/documentId"
      max_throughput     = var.database.cosmos_max_throughput
    }
    (var.database.cosmos_results_container) = {
      database_name      = var.database.cosmos_database_name
      partition_key_path = "/documentId"
      max_throughput     = var.database.cosmos_max_throughput
    }
  }

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Store Connection Strings in Key Vault
#------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = module.storage_account.primary_connection_string
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "cosmos-connection-string"
  value        = module.cosmos_db.primary_sql_connection_string
  key_vault_id = var.key_vault_id
}
