#------------------------------------------------------------------------------
# IDP Monitoring Module - Outputs
#------------------------------------------------------------------------------

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms"
  value = {
    api_5xx    = local.enabled ? aws_cloudwatch_metric_alarm.api_5xx_errors[0].arn : null
    api_4xx    = local.enabled && var.monitoring.api_4xx_threshold != null ? aws_cloudwatch_metric_alarm.api_4xx_errors[0].arn : null
    api_latency = local.enabled && var.monitoring.api_latency_p95_ms != null ? aws_cloudwatch_metric_alarm.api_latency[0].arn : null
    sfn_failed = local.enabled ? aws_cloudwatch_metric_alarm.sfn_failed_executions[0].arn : null
    sfn_throttled = local.enabled ? aws_cloudwatch_metric_alarm.sfn_throttled[0].arn : null
  }
}

output "enabled" {
  description = "Whether monitoring is enabled"
  value       = local.enabled
}
