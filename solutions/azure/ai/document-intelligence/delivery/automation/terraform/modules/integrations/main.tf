#------------------------------------------------------------------------------
# Integrations Module
# Creates cross-module connections that avoid circular dependencies:
# - Event Grid subscriptions (storage → processing)
# - Metric alerts (resources → monitoring)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Storage Event Trigger (connects storage → processing)
#------------------------------------------------------------------------------
resource "azurerm_eventgrid_event_subscription" "blob_created" {
  name  = "${var.name_prefix}-blob-trigger"
  scope = var.storage_account_id

  azure_function_endpoint {
    function_id = "${var.function_app_id}/functions/ProcessDocument"
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.input_container}/"
  }
}

#------------------------------------------------------------------------------
# Cosmos DB Alerts (connects storage → monitoring)
#------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "cosmos_ru_consumption" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.name_prefix}-cosmos-ru-high"
  resource_group_name = var.resource_group_name
  scopes              = [var.cosmos_account_id]
  description         = "Cosmos DB RU consumption is high"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "NormalizedRUConsumption"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Function App Alerts (connects processing → monitoring)
#------------------------------------------------------------------------------
resource "azurerm_monitor_metric_alert" "function_errors" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.name_prefix}-function-errors"
  resource_group_name = var.resource_group_name
  scopes              = [var.function_app_id]
  description         = "Function App error rate is high"
  severity            = 1

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "Http5xx"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}

resource "azurerm_monitor_metric_alert" "function_latency" {
  count               = var.enable_alerts ? 1 : 0
  name                = "${var.name_prefix}-function-latency"
  resource_group_name = var.resource_group_name
  scopes              = [var.function_app_id]
  description         = "Function App response time is high"
  severity            = 2

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5000
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = var.common_tags
}
