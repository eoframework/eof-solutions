#------------------------------------------------------------------------------
# Monitoring Module - Outputs
# Uses: modules/azure/monitor
#------------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = module.monitor.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = module.monitor.log_analytics_workspace_name
}

output "action_group_id" {
  description = "ID of the action group"
  value       = module.monitor.action_group_id
}

output "dashboard_id" {
  description = "ID of the dashboard"
  value       = module.monitor.dashboard_id
}
