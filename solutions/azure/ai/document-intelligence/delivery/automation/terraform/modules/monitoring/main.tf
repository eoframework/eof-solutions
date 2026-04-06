#------------------------------------------------------------------------------
# Monitoring Module
# Creates: Log Analytics Workspace, Action Group, Alerts, Dashboard
# Uses: modules/azure/monitor
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Azure Monitor (via Azure module)
#------------------------------------------------------------------------------
module "monitor" {
  source = "../../azure/monitor"

  resource_group_name = var.resource_group_name
  location            = var.location

  # Log Analytics
  create_log_analytics = true
  log_analytics_name   = "${var.name_prefix}-law"
  log_retention_days   = var.monitoring.log_retention_days

  # Action Group
  create_action_group      = true
  action_group_name        = "${var.name_prefix}-alerts"
  action_group_short_name  = "docintel"
  email_receivers = {
    operations = {
      email_address = var.monitoring.alert_email
    }
  }

  # Diagnostic Settings
  diagnostic_settings = {
    "${var.name_prefix}-func-diag" = {
      target_resource_id = var.function_app_id
      log_categories     = ["FunctionAppLogs"]
      metric_categories  = ["AllMetrics"]
    }
    "${var.name_prefix}-storage-diag" = {
      target_resource_id = "${var.storage_account_id}/blobServices/default"
      log_categories     = ["StorageRead", "StorageWrite", "StorageDelete"]
      metric_categories  = ["Transaction"]
    }
  }

  # Dashboard
  create_dashboard = var.monitoring.enable_dashboard
  dashboard_name   = var.monitoring.enable_dashboard ? "${var.name_prefix}-dashboard" : null
  dashboard_properties = var.monitoring.enable_dashboard ? jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x       = 0
              y       = 0
              colSpan = 6
              rowSpan = 4
            }
            metadata = {
              type = "Extension/HubsExtension/PartType/MarkdownPart"
              settings = {
                content = {
                  settings = {
                    content = "# Document Intelligence Dashboard\n\nMonitoring for document processing pipeline."
                  }
                }
              }
            }
          }
        }
      }
    }
    metadata = {
      model = {}
    }
  }) : null

  common_tags = var.common_tags
}
