# AWS Config Rules Module - Outputs

output "config_recorder_id" {
  description = "AWS Config recorder ID"
  value       = var.config_rules.create_recorder ? aws_config_configuration_recorder.main[0].id : null
}

output "config_bucket_name" {
  description = "S3 bucket name for Config delivery"
  value       = var.config_rules.create_recorder && var.config_bucket_name == "" ? aws_s3_bucket.config[0].id : var.config_bucket_name
}

output "config_bucket_arn" {
  description = "S3 bucket ARN for Config delivery"
  value       = var.config_rules.create_recorder && var.config_bucket_name == "" ? aws_s3_bucket.config[0].arn : null
}

output "config_role_arn" {
  description = "IAM role ARN for AWS Config"
  value       = var.config_rules.create_recorder ? aws_iam_role.config[0].arn : null
}

output "config_rules" {
  description = "Map of created Config rule names and ARNs"
  value = merge(
    var.config_rules.enable_security_rules ? {
      encrypted_volumes = try(aws_config_config_rule.encrypted_volumes[0].arn, null)
      rds_encryption    = try(aws_config_config_rule.rds_encryption[0].arn, null)
      s3_bucket_ssl     = try(aws_config_config_rule.s3_bucket_ssl[0].arn, null)
      vpc_flow_logs     = try(aws_config_config_rule.vpc_flow_logs[0].arn, null)
      root_mfa          = try(aws_config_config_rule.root_mfa[0].arn, null)
    } : {},
    var.config_rules.enable_reliability_rules ? {
      rds_multi_az   = try(aws_config_config_rule.rds_multi_az[0].arn, null)
      elb_cross_zone = try(aws_config_config_rule.elb_cross_zone[0].arn, null)
      db_backup      = try(aws_config_config_rule.db_backup[0].arn, null)
    } : {},
    var.config_rules.enable_operational_rules ? {
      cloudwatch_alarm = try(aws_config_config_rule.cloudwatch_alarm_action[0].arn, null)
      cloudtrail       = try(aws_config_config_rule.cloudtrail_enabled[0].arn, null)
    } : {},
    var.config_rules.enable_cost_rules ? {
      ebs_optimized = try(aws_config_config_rule.ebs_optimized[0].arn, null)
    } : {}
  )
}
