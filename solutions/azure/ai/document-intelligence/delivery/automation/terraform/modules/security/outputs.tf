#------------------------------------------------------------------------------
# Security Module - Outputs
#------------------------------------------------------------------------------

output "managed_identity_id" {
  description = "ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "managed_identity_client_id" {
  description = "Client ID of the managed identity"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "encryption_key_id" {
  description = "ID of the encryption key"
  value       = var.security.enable_customer_managed_key ? azurerm_key_vault_key.encryption[0].id : null
}

output "encryption_key_version" {
  description = "Version of the encryption key"
  value       = var.security.enable_customer_managed_key ? azurerm_key_vault_key.encryption[0].version : null
}
