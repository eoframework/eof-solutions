#------------------------------------------------------------------------------
# Best Practices Module - Outputs
#------------------------------------------------------------------------------

output "recovery_vault_id" {
  description = "ID of the Recovery Services Vault"
  value       = var.backup.enabled ? azurerm_recovery_services_vault.main[0].id : null
}

output "recovery_vault_name" {
  description = "Name of the Recovery Services Vault"
  value       = var.backup.enabled ? azurerm_recovery_services_vault.main[0].name : null
}

output "budget_id" {
  description = "ID of the consumption budget"
  value       = var.budget.enabled ? azurerm_consumption_budget_resource_group.main[0].id : null
}
