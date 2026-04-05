#------------------------------------------------------------------------------
# Best Practices Module
#------------------------------------------------------------------------------
# Consolidated module for AWS best practices aligned with Well-Architected Framework:
# - Operational Excellence: AWS Config Rules
# - Security: Enhanced GuardDuty
# - Reliability: AWS Backup Plans
# - Cost Optimization: AWS Budgets
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Operational Excellence: AWS Config Rules
#------------------------------------------------------------------------------
module "config_rules" {
  source = "../aws/best-practices/operational-excellence/config-rules"
  count  = var.config_rules.enabled ? 1 : 0

  name_prefix        = var.name_prefix
  common_tags        = var.common_tags
  kms_key_arn        = var.kms_key_arn
  sns_topic_arn      = var.sns_topic_arn
  config_bucket_name = var.config_bucket_name != "" ? var.config_bucket_name : "${var.name_prefix}-config"

  config_rules = {
    enabled                   = var.config_rules.enabled
    create_recorder           = var.config_rules.enable_recorder
    retention_days            = var.config_rules.retention_days
    enable_security_rules     = true
    enable_reliability_rules  = true
    enable_operational_rules  = true
    enable_cost_rules         = true
  }
}

#------------------------------------------------------------------------------
# Security: Enhanced GuardDuty
#------------------------------------------------------------------------------
module "guardduty_enhanced" {
  source = "../aws/best-practices/security/guardduty"
  count  = var.guardduty_enhanced.enabled ? 1 : 0

  name_prefix         = var.name_prefix
  common_tags         = var.common_tags
  kms_key_arn         = var.kms_key_arn
  sns_topic_arn       = var.sns_topic_arn
  findings_bucket_arn = var.guardduty_findings_bucket != "" ? "arn:aws:s3:::${var.guardduty_findings_bucket}" : ""

  guardduty = {
    enabled                   = var.guardduty_enhanced.enabled
    enable_s3_protection      = true
    enable_eks_protection     = var.guardduty_enhanced.enable_eks_protection
    enable_malware_protection = var.guardduty_enhanced.enable_malware_protection
    enable_s3_export          = true
    enable_alerts             = true
    alert_severity_threshold  = var.guardduty_enhanced.severity_threshold
  }
}

#------------------------------------------------------------------------------
# Reliability: AWS Backup Plans
#------------------------------------------------------------------------------
module "backup_plans" {
  source = "../aws/best-practices/reliability/backup-plans"
  count  = var.backup.enabled ? 1 : 0

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix    = var.name_prefix
  common_tags    = var.common_tags
  kms_key_arn    = var.kms_key_arn
  dr_kms_key_arn = var.dr_kms_key_arn
  sns_topic_arn  = var.sns_topic_arn

  backup = {
    enabled                    = var.backup.enabled
    daily_schedule             = var.backup.daily_schedule
    daily_retention            = var.backup.daily_retention
    enable_weekly              = true
    weekly_schedule            = var.backup.weekly_schedule
    weekly_retention           = var.backup.weekly_retention
    enable_monthly             = true
    monthly_schedule           = var.backup.monthly_schedule
    monthly_retention          = var.backup.monthly_retention
    cold_storage_days          = var.backup.cold_storage_days
    enable_cross_region        = var.backup.enable_cross_region
    dr_retention               = var.backup.dr_retention
    enable_tag_selection       = true
    backup_tag_key             = "Backup"
    backup_tag_value           = "true"
    enable_continuous          = var.backup.enable_continuous
    enable_windows_vss         = var.backup.enable_windows_vss
    enable_vault_lock          = var.backup.enable_vault_lock
    vault_lock_min_retention   = var.backup.vault_lock_min_retention
    vault_lock_max_retention   = var.backup.vault_lock_max_retention
    vault_lock_changeable_days = var.backup.vault_lock_changeable_days
    notification_events = [
      "BACKUP_JOB_STARTED",
      "BACKUP_JOB_COMPLETED",
      "BACKUP_JOB_FAILED",
      "RESTORE_JOB_COMPLETED",
      "RESTORE_JOB_FAILED"
    ]
  }
}

#------------------------------------------------------------------------------
# Cost Optimization: AWS Budgets
#------------------------------------------------------------------------------
module "budgets" {
  source = "../aws/best-practices/cost-optimization/budgets"
  count  = var.budget.enabled ? 1 : 0

  name_prefix    = var.name_prefix
  common_tags    = var.common_tags
  environment    = var.environment
  sns_topic_arns = [var.sns_topic_arn]

  budget = {
    enabled                     = var.budget.enabled
    enable_cost_budget          = true
    monthly_amount              = var.budget.monthly_amount
    alert_thresholds            = var.budget.alert_thresholds
    enable_forecast_alert       = true
    forecast_threshold          = var.budget.forecast_threshold
    alert_emails                = var.budget.alert_emails
    enable_service_budgets      = var.budget.enable_service_budgets
    ec2_budget_amount           = var.budget.ec2_budget_amount
    rds_budget_amount           = var.budget.rds_budget_amount
    data_transfer_budget_amount = var.budget.data_transfer_budget_amount
    enable_usage_budget         = var.budget.enable_usage_budget
    ec2_usage_hours_limit       = var.budget.ec2_usage_hours_limit
    enable_actions              = var.budget.enable_actions
    action_approval             = var.budget.action_approval
    action_threshold            = var.budget.action_threshold
    ec2_instances_to_stop       = var.budget.ec2_instances_to_stop
  }
}
