#------------------------------------------------------------------------------
# Processing Module - Outputs
# Uses: modules/azure/document-intelligence, modules/azure/function-app, modules/azure/logic-app
#------------------------------------------------------------------------------

output "document_intelligence_id" {
  description = "ID of the Document Intelligence account"
  value       = module.document_intelligence.id
}

output "document_intelligence_endpoint" {
  description = "Endpoint of the Document Intelligence account"
  value       = module.document_intelligence.endpoint
}

output "function_app_id" {
  description = "ID of the Function App"
  value       = module.function_app.id
}

output "function_app_name" {
  description = "Name of the Function App"
  value       = module.function_app.name
}

output "function_app_url" {
  description = "URL of the Function App"
  value       = "https://${module.function_app.default_hostname}"
}

output "function_app_identity_principal_id" {
  description = "Principal ID of the Function App managed identity"
  value       = module.function_app.principal_id
}

output "logic_app_id" {
  description = "ID of the Logic App"
  value       = module.logic_app.id
}

output "logic_app_url" {
  description = "URL of the Logic App"
  value       = module.logic_app.access_endpoint
}

output "application_insights_id" {
  description = "ID of Application Insights"
  value       = azurerm_application_insights.main.id
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}
