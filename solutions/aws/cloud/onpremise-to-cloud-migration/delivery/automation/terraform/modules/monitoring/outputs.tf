#------------------------------------------------------------------------------
# Cloud Migration - Monitoring Module Outputs
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
    alb_5xx         = aws_cloudwatch_metric_alarm.alb_5xx.arn
    ec2_cpu         = aws_cloudwatch_metric_alarm.ec2_cpu.arn
    rds_cpu         = aws_cloudwatch_metric_alarm.rds_cpu.arn
    rds_connections = aws_cloudwatch_metric_alarm.rds_connections.arn
    rds_storage_low = aws_cloudwatch_metric_alarm.rds_storage_low.arn
  }
}
