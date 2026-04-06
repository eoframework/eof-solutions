#------------------------------------------------------------------------------
# Azure Monitor Module
#------------------------------------------------------------------------------
# Creates monitoring resources:
# - Log Analytics Workspace
# - Application Insights
# - Action Groups
# - Diagnostic Settings
# - Dashboard
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Log Analytics Workspace
#------------------------------------------------------------------------------
resource "azurerm_log_analytics_workspace" "this" {
  count = var.create_log_analytics ? 1 : 0

  name                = var.log_analytics_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  daily_quota_gb                     = var.daily_quota_gb
  internet_ingestion_enabled         = var.internet_ingestion_enabled
  internet_query_enabled             = var.internet_query_enabled
  reservation_capacity_in_gb_per_day = var.reservation_capacity_gb

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Application Insights
#------------------------------------------------------------------------------
resource "azurerm_application_insights" "this" {
  count = var.create_app_insights ? 1 : 0

  name                = var.app_insights_name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_type
  workspace_id        = var.create_log_analytics ? azurerm_log_analytics_workspace.this[0].id : var.log_analytics_workspace_id

  retention_in_days                     = var.app_insights_retention_days
  daily_data_cap_in_gb                  = var.daily_data_cap_gb
  daily_data_cap_notifications_disabled = var.daily_data_cap_notifications_disabled
  sampling_percentage                   = var.sampling_percentage
  disable_ip_masking                    = var.disable_ip_masking
  local_authentication_disabled         = var.local_authentication_disabled

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Action Group
#------------------------------------------------------------------------------
resource "azurerm_monitor_action_group" "this" {
  count = var.create_action_group ? 1 : 0

  name                = var.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name
  enabled             = var.action_group_enabled

  dynamic "email_receiver" {
    for_each = var.email_receivers
    content {
      name                    = email_receiver.key
      email_address           = email_receiver.value.email_address
      use_common_alert_schema = lookup(email_receiver.value, "use_common_alert_schema", true)
    }
  }

  dynamic "sms_receiver" {
    for_each = var.sms_receivers
    content {
      name         = sms_receiver.key
      country_code = sms_receiver.value.country_code
      phone_number = sms_receiver.value.phone_number
    }
  }

  dynamic "webhook_receiver" {
    for_each = var.webhook_receivers
    content {
      name                    = webhook_receiver.key
      service_uri             = webhook_receiver.value.service_uri
      use_common_alert_schema = lookup(webhook_receiver.value, "use_common_alert_schema", true)
    }
  }

  dynamic "azure_function_receiver" {
    for_each = var.azure_function_receivers
    content {
      name                     = azure_function_receiver.key
      function_app_resource_id = azure_function_receiver.value.function_app_resource_id
      function_name            = azure_function_receiver.value.function_name
      http_trigger_url         = azure_function_receiver.value.http_trigger_url
      use_common_alert_schema  = lookup(azure_function_receiver.value, "use_common_alert_schema", true)
    }
  }

  dynamic "logic_app_receiver" {
    for_each = var.logic_app_receivers
    content {
      name                    = logic_app_receiver.key
      resource_id             = logic_app_receiver.value.resource_id
      callback_url            = logic_app_receiver.value.callback_url
      use_common_alert_schema = lookup(logic_app_receiver.value, "use_common_alert_schema", true)
    }
  }

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Diagnostic Settings
#------------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.key
  target_resource_id             = each.value.target_resource_id
  log_analytics_workspace_id     = var.create_log_analytics ? azurerm_log_analytics_workspace.this[0].id : var.log_analytics_workspace_id
  storage_account_id             = lookup(each.value, "storage_account_id", null)
  eventhub_authorization_rule_id = lookup(each.value, "eventhub_authorization_rule_id", null)
  eventhub_name                  = lookup(each.value, "eventhub_name", null)

  dynamic "enabled_log" {
    for_each = lookup(each.value, "log_categories", [])
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = lookup(each.value, "metric_categories", [])
    content {
      category = metric.value
      enabled  = true
    }
  }
}

#------------------------------------------------------------------------------
# Dashboard
#------------------------------------------------------------------------------
resource "azurerm_portal_dashboard" "this" {
  count = var.create_dashboard ? 1 : 0

  name                 = var.dashboard_name
  resource_group_name  = var.resource_group_name
  location             = var.location
  dashboard_properties = var.dashboard_properties

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}
