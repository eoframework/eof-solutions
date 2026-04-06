#------------------------------------------------------------------------------
# Best Practices Module
# Creates: Backup Vault, Budgets, Azure Policies
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Recovery Services Vault for Backups
#------------------------------------------------------------------------------
resource "azurerm_recovery_services_vault" "main" {
  count               = var.backup.enabled ? 1 : 0
  name                = "${var.name_prefix}-rsv"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Consumption Budget
#------------------------------------------------------------------------------
resource "azurerm_consumption_budget_resource_group" "main" {
  count             = var.budget.enabled ? 1 : 0
  name              = "${var.name_prefix}-budget"
  resource_group_id = data.azurerm_resource_group.main.id
  amount            = var.budget.monthly_amount
  time_grain        = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
  }

  dynamic "notification" {
    for_each = var.budget.alert_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      operator       = "GreaterThan"
      threshold_type = "Actual"

      contact_emails = [var.budget.notification_email]
    }
  }
}

data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

#------------------------------------------------------------------------------
# Azure Policy Assignments
#------------------------------------------------------------------------------
# Require encryption on storage accounts
resource "azurerm_resource_group_policy_assignment" "require_encryption" {
  count                = var.policy.enable_security_policies ? 1 : 0
  name                 = "${var.name_prefix}-require-encryption"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9"
  description          = "Require secure transfer for storage accounts"
  display_name         = "Require encryption in transit"
}

# Require tags on resources
resource "azurerm_resource_group_policy_assignment" "require_tags" {
  count                = var.policy.enable_operational_policies ? 1 : 0
  name                 = "${var.name_prefix}-require-tags"
  resource_group_id    = data.azurerm_resource_group.main.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  description          = "Require ManagedBy tag on resources"
  display_name         = "Require ManagedBy tag"

  parameters = jsonencode({
    tagName = {
      value = "ManagedBy"
    }
  })
}
