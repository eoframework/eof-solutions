#------------------------------------------------------------------------------
# Azure Cosmos DB Module
#------------------------------------------------------------------------------
# Creates Cosmos DB account with:
# - SQL API databases and containers
# - Automatic failover and geo-replication
# - Customer-managed encryption
# - Network rules and private endpoints
#------------------------------------------------------------------------------

resource "azurerm_cosmosdb_account" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  offer_type          = "Standard"
  kind                = var.kind

  # Consistency policy
  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.max_interval_in_seconds
    max_staleness_prefix    = var.max_staleness_prefix
  }

  # Geo-locations
  dynamic "geo_location" {
    for_each = var.geo_locations
    content {
      location          = geo_location.value.location
      failover_priority = geo_location.value.failover_priority
      zone_redundant    = lookup(geo_location.value, "zone_redundant", false)
    }
  }

  # Capabilities
  dynamic "capabilities" {
    for_each = var.capabilities
    content {
      name = capabilities.value
    }
  }

  # Backup policy
  dynamic "backup" {
    for_each = var.backup_type != null ? [1] : []
    content {
      type                = var.backup_type
      interval_in_minutes = var.backup_interval_minutes
      retention_in_hours  = var.backup_retention_hours
      storage_redundancy  = var.backup_storage_redundancy
    }
  }

  # Network rules
  is_virtual_network_filter_enabled = var.enable_virtual_network_filter
  public_network_access_enabled     = var.public_network_access_enabled
  ip_range_filter                   = var.ip_range_filter

  dynamic "virtual_network_rule" {
    for_each = var.virtual_network_rules
    content {
      id                                   = virtual_network_rule.value.subnet_id
      ignore_missing_vnet_service_endpoint = lookup(virtual_network_rule.value, "ignore_missing_endpoint", false)
    }
  }

  # Encryption
  key_vault_key_id = var.key_vault_key_id

  # Identity
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  # Performance options (azurerm 4.x attribute names)
  automatic_failover_enabled       = var.automatic_failover_enabled
  multiple_write_locations_enabled = var.multiple_write_locations_enabled
  free_tier_enabled                = var.free_tier_enabled
  analytical_storage_enabled       = var.analytical_storage_enabled
  local_authentication_disabled    = var.local_authentication_disabled

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# SQL Databases
#------------------------------------------------------------------------------
resource "azurerm_cosmosdb_sql_database" "this" {
  for_each = var.sql_databases

  name                = each.key
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  throughput          = lookup(each.value, "throughput", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }
}

#------------------------------------------------------------------------------
# SQL Containers
#------------------------------------------------------------------------------
resource "azurerm_cosmosdb_sql_container" "this" {
  for_each = var.sql_containers

  name                  = each.key
  resource_group_name   = var.resource_group_name
  account_name          = azurerm_cosmosdb_account.this.name
  database_name         = azurerm_cosmosdb_sql_database.this[each.value.database_name].name
  partition_key_path    = each.value.partition_key_path
  partition_key_version = lookup(each.value, "partition_key_version", 1)
  throughput            = lookup(each.value, "throughput", null)
  default_ttl           = lookup(each.value, "default_ttl", null)

  dynamic "autoscale_settings" {
    for_each = lookup(each.value, "max_throughput", null) != null ? [1] : []
    content {
      max_throughput = each.value.max_throughput
    }
  }

  dynamic "indexing_policy" {
    for_each = lookup(each.value, "indexing_policy", null) != null ? [each.value.indexing_policy] : []
    content {
      indexing_mode = lookup(indexing_policy.value, "indexing_mode", "consistent")

      dynamic "included_path" {
        for_each = lookup(indexing_policy.value, "included_paths", ["/*"])
        content {
          path = included_path.value
        }
      }

      dynamic "excluded_path" {
        for_each = lookup(indexing_policy.value, "excluded_paths", [])
        content {
          path = excluded_path.value
        }
      }
    }
  }

  dynamic "unique_key" {
    for_each = lookup(each.value, "unique_keys", [])
    content {
      paths = unique_key.value.paths
    }
  }
}
