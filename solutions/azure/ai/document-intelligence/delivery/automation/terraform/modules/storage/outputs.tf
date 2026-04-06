#------------------------------------------------------------------------------
# Storage Module - Outputs
# Uses: modules/azure/storage-account, modules/azure/cosmos-db
#------------------------------------------------------------------------------

output "storage_account_id" {
  description = "ID of the storage account"
  value       = module.storage_account.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage_account.name
}

output "storage_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = module.storage_account.primary_blob_endpoint
}

output "storage_connection_string" {
  description = "Storage account connection string"
  value       = module.storage_account.primary_connection_string
  sensitive   = true
}

output "cosmos_account_id" {
  description = "ID of the Cosmos DB account"
  value       = module.cosmos_db.id
}

output "cosmos_account_name" {
  description = "Name of the Cosmos DB account"
  value       = module.cosmos_db.name
}

output "cosmos_endpoint" {
  description = "Cosmos DB endpoint"
  value       = module.cosmos_db.endpoint
}

output "cosmos_key" {
  description = "Cosmos DB primary key"
  value       = module.cosmos_db.primary_key
  sensitive   = true
}

output "cosmos_database_name" {
  description = "Cosmos DB database name"
  value       = var.database.cosmos_database_name
}
