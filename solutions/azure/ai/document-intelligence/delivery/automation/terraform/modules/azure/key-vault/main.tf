#------------------------------------------------------------------------------
# Azure Key Vault Module
#------------------------------------------------------------------------------
# Creates Key Vault with:
# - RBAC or access policy authorization
# - Customer-managed keys
# - Network rules and private endpoints
# - Soft delete and purge protection
#------------------------------------------------------------------------------

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name

  # Security settings
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  purge_protection_enabled        = var.purge_protection_enabled
  soft_delete_retention_days      = var.soft_delete_retention_days
  public_network_access_enabled   = var.public_network_access_enabled

  # Network rules
  dynamic "network_acls" {
    for_each = var.enable_network_acls ? [1] : []
    content {
      bypass                     = var.network_bypass
      default_action             = var.network_default_action
      ip_rules                   = var.allowed_ip_ranges
      virtual_network_subnet_ids = var.allowed_subnet_ids
    }
  }

  # Access policies (when not using RBAC)
  dynamic "access_policy" {
    for_each = var.enable_rbac_authorization ? [] : var.access_policies
    content {
      tenant_id               = var.tenant_id
      object_id               = access_policy.value.object_id
      key_permissions         = lookup(access_policy.value, "key_permissions", [])
      secret_permissions      = lookup(access_policy.value, "secret_permissions", [])
      certificate_permissions = lookup(access_policy.value, "certificate_permissions", [])
      storage_permissions     = lookup(access_policy.value, "storage_permissions", [])
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Keys
#------------------------------------------------------------------------------
resource "azurerm_key_vault_key" "this" {
  for_each = var.keys

  name         = each.key
  key_vault_id = azurerm_key_vault.this.id
  key_type     = each.value.key_type
  key_size     = lookup(each.value, "key_size", 2048)
  key_opts     = each.value.key_opts

  lifecycle {
    ignore_changes = [tags]
  }

  dynamic "rotation_policy" {
    for_each = lookup(each.value, "rotation_policy", null) != null ? [each.value.rotation_policy] : []
    content {
      expire_after         = lookup(rotation_policy.value, "expire_after", null)
      notify_before_expiry = lookup(rotation_policy.value, "notify_before_expiry", null)

      dynamic "automatic" {
        for_each = lookup(rotation_policy.value, "time_after_creation", null) != null ? [1] : []
        content {
          time_after_creation = rotation_policy.value.time_after_creation
        }
      }
    }
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Secrets
#------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "this" {
  for_each = var.secrets

  name            = each.key
  value           = each.value.value
  key_vault_id    = azurerm_key_vault.this.id
  content_type    = lookup(each.value, "content_type", null)
  expiration_date = lookup(each.value, "expiration_date", null)
  not_before_date = lookup(each.value, "not_before_date", null)

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# RBAC Role Assignments
#------------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  for_each = var.enable_rbac_authorization ? var.role_assignments : {}

  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id
}
