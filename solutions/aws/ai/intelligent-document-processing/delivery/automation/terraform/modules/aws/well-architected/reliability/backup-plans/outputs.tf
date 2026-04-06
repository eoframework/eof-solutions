# AWS Backup Plans Module - Outputs

output "vault_name" {
  description = "Backup vault name"
  value       = aws_backup_vault.main.name
}

output "vault_arn" {
  description = "Backup vault ARN"
  value       = aws_backup_vault.main.arn
}

output "vault_recovery_points" {
  description = "Number of recovery points in vault"
  value       = aws_backup_vault.main.recovery_points
}

output "dr_vault_name" {
  description = "DR backup vault name"
  value       = var.backup.enable_cross_region ? aws_backup_vault.dr[0].name : null
}

output "dr_vault_arn" {
  description = "DR backup vault ARN"
  value       = var.backup.enable_cross_region ? aws_backup_vault.dr[0].arn : null
}

output "backup_plan_id" {
  description = "Backup plan ID"
  value       = aws_backup_plan.daily.id
}

output "backup_plan_arn" {
  description = "Backup plan ARN"
  value       = aws_backup_plan.daily.arn
}

output "backup_role_arn" {
  description = "IAM role ARN for AWS Backup"
  value       = aws_iam_role.backup.arn
}
