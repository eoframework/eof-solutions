# AWS GuardDuty Module - Outputs

output "detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "detector_arn" {
  description = "GuardDuty detector ARN"
  value       = aws_guardduty_detector.main.arn
}

output "findings_bucket_name" {
  description = "S3 bucket name for findings export"
  value       = var.guardduty.enable_s3_export && var.findings_bucket_arn == "" ? aws_s3_bucket.findings[0].id : null
}

output "findings_bucket_arn" {
  description = "S3 bucket ARN for findings export"
  value       = var.guardduty.enable_s3_export && var.findings_bucket_arn == "" ? aws_s3_bucket.findings[0].arn : var.findings_bucket_arn
}

output "event_rule_arn" {
  description = "EventBridge rule ARN for high severity findings"
  value       = var.guardduty.enable_alerts ? aws_cloudwatch_event_rule.high_severity[0].arn : null
}
