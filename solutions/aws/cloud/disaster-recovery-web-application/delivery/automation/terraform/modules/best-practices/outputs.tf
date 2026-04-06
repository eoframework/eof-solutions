#------------------------------------------------------------------------------
# Best Practices Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Config Rules Outputs
#------------------------------------------------------------------------------

output "config_recorder_id" {
  description = "AWS Config recorder ID"
  value       = var.config_rules.enabled ? module.config_rules[0].config_recorder_id : null
}

output "config_bucket_name" {
  description = "S3 bucket for AWS Config"
  value       = var.config_rules.enabled ? module.config_rules[0].config_bucket_name : null
}

#------------------------------------------------------------------------------
# GuardDuty Outputs
#------------------------------------------------------------------------------

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = var.guardduty_enhanced.enabled ? module.guardduty_enhanced[0].detector_id : null
}

#------------------------------------------------------------------------------
# Backup Outputs
#------------------------------------------------------------------------------

output "backup_vault_name" {
  description = "AWS Backup vault name"
  value       = var.backup.enabled ? module.backup_plans[0].backup_vault_name : null
}

output "backup_vault_arn" {
  description = "AWS Backup vault ARN"
  value       = var.backup.enabled ? module.backup_plans[0].backup_vault_arn : null
}

#------------------------------------------------------------------------------
# Budget Outputs
#------------------------------------------------------------------------------

output "budget_name" {
  description = "AWS Budget name"
  value       = var.budget.enabled ? module.budgets[0].budget_name : null
}
