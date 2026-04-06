#------------------------------------------------------------------------------
# Disaster Recovery Module - Outputs
#------------------------------------------------------------------------------

output "dr_resource_group_name" {
  description = "Name of the DR resource group"
  value       = azurerm_resource_group.dr.name
}

output "dr_resource_group_id" {
  description = "ID of the DR resource group"
  value       = azurerm_resource_group.dr.id
}

output "storage_account_id" {
  description = "ID of the DR storage account"
  value       = azurerm_storage_account.dr.id
}

output "storage_account_name" {
  description = "Name of the DR storage account"
  value       = azurerm_storage_account.dr.name
}

output "dr_location" {
  description = "DR region location"
  value       = var.dr_location
}
