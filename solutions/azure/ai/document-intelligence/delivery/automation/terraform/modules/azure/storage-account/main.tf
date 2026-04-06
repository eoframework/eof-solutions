#------------------------------------------------------------------------------
# Azure Storage Account Module
#------------------------------------------------------------------------------
# Creates Storage Accounts with:
# - Blob containers with access policies
# - Lifecycle management rules
# - KMS encryption (Customer-managed keys)
# - Network rules and private endpoints
# - Replication configuration
#------------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.replication_type
  account_kind                    = var.account_kind
  access_tier                     = var.access_tier
  min_tls_version                 = var.min_tls_version
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = var.allow_public_access
  shared_access_key_enabled       = var.shared_access_key_enabled
  public_network_access_enabled   = var.public_network_access_enabled

  # Blob properties
  blob_properties {
    versioning_enabled       = var.versioning_enabled
    change_feed_enabled      = var.change_feed_enabled
    last_access_time_enabled = var.last_access_time_enabled

    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_days > 0 ? [1] : []
      content {
        days = var.blob_soft_delete_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_days > 0 ? [1] : []
      content {
        days = var.container_soft_delete_days
      }
    }

    dynamic "cors_rule" {
      for_each = var.cors_rules
      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.enable_network_rules ? [1] : []
    content {
      default_action             = var.network_default_action
      bypass                     = var.network_bypass
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  # Customer-managed encryption key
  dynamic "customer_managed_key" {
    for_each = var.customer_managed_key_id != null ? [1] : []
    content {
      key_vault_key_id          = var.customer_managed_key_id
      user_assigned_identity_id = var.identity_id
    }
  }

  # Identity for CMK
  dynamic "identity" {
    for_each = var.identity_type != null ? [1] : []
    content {
      type         = var.identity_type
      identity_ids = var.identity_ids
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Blob Containers
#------------------------------------------------------------------------------
resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = lookup(each.value, "access_type", "private")
}

#------------------------------------------------------------------------------
# Lifecycle Management Policy
#------------------------------------------------------------------------------
resource "azurerm_storage_management_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      name    = rule.key
      enabled = lookup(rule.value, "enabled", true)

      filters {
        prefix_match = lookup(rule.value, "prefix_match", [])
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
      }

      actions {
        dynamic "base_blob" {
          for_each = lookup(rule.value, "base_blob_actions", null) != null ? [rule.value.base_blob_actions] : []
          content {
            tier_to_cool_after_days_since_modification_greater_than    = lookup(base_blob.value, "tier_to_cool_days", null)
            tier_to_archive_after_days_since_modification_greater_than = lookup(base_blob.value, "tier_to_archive_days", null)
            delete_after_days_since_modification_greater_than          = lookup(base_blob.value, "delete_days", null)
          }
        }

        dynamic "snapshot" {
          for_each = lookup(rule.value, "snapshot_actions", null) != null ? [rule.value.snapshot_actions] : []
          content {
            delete_after_days_since_creation_greater_than = lookup(snapshot.value, "delete_days", null)
          }
        }

        dynamic "version" {
          for_each = lookup(rule.value, "version_actions", null) != null ? [rule.value.version_actions] : []
          content {
            delete_after_days_since_creation = lookup(version.value, "delete_days", null)
          }
        }
      }
    }
  }
}
