#------------------------------------------------------------------------------
# Core Infrastructure Module - Outputs
# Uses: modules/azure/vnet, modules/azure/key-vault
#------------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.vnet.name
}

output "functions_subnet_id" {
  description = "ID of the Functions subnet"
  value       = module.vnet.subnet_ids["${var.name_prefix}-functions-subnet"]
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet"
  value       = module.vnet.subnet_ids["${var.name_prefix}-pe-subnet"]
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.key_vault.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.vault_uri
}
