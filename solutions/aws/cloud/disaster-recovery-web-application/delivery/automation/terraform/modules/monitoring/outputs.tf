#------------------------------------------------------------------------------
# DR Web Application Monitoring Module - Outputs
#------------------------------------------------------------------------------

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarms" {
  description = "Map of CloudWatch alarm ARNs"
  value = {
    alb_5xx          = aws_cloudwatch_metric_alarm.alb_5xx.arn
    alb_latency      = aws_cloudwatch_metric_alarm.alb_latency.arn
    unhealthy_hosts  = aws_cloudwatch_metric_alarm.unhealthy_hosts.arn
    aurora_cpu       = aws_cloudwatch_metric_alarm.aurora_cpu.arn
    aurora_connections = aws_cloudwatch_metric_alarm.aurora_connections.arn
  }
}
