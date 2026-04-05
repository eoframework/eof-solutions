#------------------------------------------------------------------------------
# DR Web Application - Disaster Recovery Module Outputs
#------------------------------------------------------------------------------

output "health_check_id" {
  description = "ID of the Route 53 health check"
  value       = var.dns.hosted_zone_id != "" ? aws_route53_health_check.primary[0].id : null
}

output "dr_kms_key_arn" {
  description = "ARN of the DR region KMS key"
  value       = local.vault_enabled ? aws_kms_key.dr[0].arn : null
}

output "dr_kms_key_id" {
  description = "ID of the DR region KMS key"
  value       = local.vault_enabled ? aws_kms_key.dr[0].key_id : null
}

output "dr_bucket_arn" {
  description = "ARN of the DR S3 bucket"
  value       = local.vault_enabled ? aws_s3_bucket.dr[0].arn : null
}

output "dr_bucket_id" {
  description = "ID of the DR S3 bucket"
  value       = local.vault_enabled ? aws_s3_bucket.dr[0].id : null
}

output "dr_backup_vault_arn" {
  description = "ARN of the DR backup vault"
  value       = local.vault_enabled ? aws_backup_vault.dr[0].arn : null
}

output "primary_backup_vault_arn" {
  description = "ARN of the primary backup vault"
  value       = var.dr.replication_enabled ? aws_backup_vault.primary[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = var.dr.replication_enabled ? aws_backup_plan.main[0].id : null
}

output "backup_role_arn" {
  description = "ARN of the backup IAM role"
  value       = var.dr.replication_enabled ? aws_iam_role.backup[0].arn : null
}
