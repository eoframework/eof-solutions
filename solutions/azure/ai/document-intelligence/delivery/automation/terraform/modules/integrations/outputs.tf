#------------------------------------------------------------------------------
# Integrations Module - Outputs
#------------------------------------------------------------------------------

output "event_subscription_id" {
  description = "ID of the blob created event subscription"
  value       = azurerm_eventgrid_event_subscription.blob_created.id
}

output "cosmos_alert_id" {
  description = "ID of the Cosmos DB RU consumption alert"
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.cosmos_ru_consumption[0].id : null
}

output "function_error_alert_id" {
  description = "ID of the Function App error alert"
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.function_errors[0].id : null
}

output "function_latency_alert_id" {
  description = "ID of the Function App latency alert"
  value       = var.enable_alerts ? azurerm_monitor_metric_alert.function_latency[0].id : null
}
