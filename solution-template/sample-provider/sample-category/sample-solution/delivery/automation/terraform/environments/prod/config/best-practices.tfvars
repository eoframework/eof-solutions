#------------------------------------------------------------------------------
# AWS Well-Architected Best Practices - Backup, Budgets, Config Rules, GuardDuty - PROD Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-11-30 15:48:17
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

backup = {
  backup_tag_key = "Backup"  # Backup tag key
  backup_tag_value = "true"  # Backup tag value
  cold_storage_days = 90  # Days before cold storage transition
  daily_retention = 30  # Daily backup retention (days)
  daily_schedule = "cron(0 5 * * ? *)"  # Daily backup schedule (cron)
  dr_retention = 30  # DR backup retention (days)
  enable_continuous = false  # Enable continuous backup
  enable_cross_region = false  # Enable cross-region backup copy
  enable_monthly = true  # Enable Monthly
  enable_s3_backup = false  # Enable S3 Backup
  enable_tag_selection = true  # Enable tag-based resource selection
  enable_vault_lock = false  # Enable vault lock
  enable_vault_policy = true  # Enable vault policy
  enable_weekly = true  # Enable Weekly
  enable_windows_vss = false  # Enable Windows Vss
  enabled = true  # Enable this resource
  monthly_retention = 365  # Monthly backup retention (days)
  monthly_schedule = "cron(0 5 1 * ? *)"  # Monthly backup schedule (cron)
  notification_events = ["BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED", "BACKUP_JOB_FAILED", "RESTORE_JOB_STARTED", "RESTORE_JOB_COMPLETED", "RESTORE_JOB_FAILED"]  # Backup notification events
  resource_arns = []  # Specific resource ARNs to backup
  vault_lock_changeable_days = 3  # Vault Lock Changeable Days
  vault_lock_max_retention = 365  # Vault Lock Max Retention
  vault_lock_min_retention = 7  # Vault Lock Min Retention
  weekly_retention = 90  # Weekly backup retention (days)
  weekly_schedule = "cron(0 5 ? * SUN *)"  # Weekly backup schedule (cron)
}

budget = {
  action_approval = "MANUAL"  # Budget action approval mode
  action_threshold = 100  # Budget action threshold (%)
  alert_emails = []  # Budget alert email addresses
  alert_thresholds = [50, 80, 100]  # Budget alert threshold percentages
  budget_currency = "USD"  # Budget currency
  budget_time_unit = "MONTHLY"  # Budget time unit
  data_transfer_budget_amount = 0  # Data transfer monthly budget (USD)
  ec2_budget_amount = 0  # EC2 monthly budget (USD)
  ec2_instances_to_stop = []  # Ec2 Instances To Stop
  ec2_usage_hours_limit = 1000  # EC2 monthly usage limit (hours)
  enable_actions = false  # Enable budget actions
  enable_cost_budget = true  # Enable cost budget
  enable_forecast_alert = true  # Enable forecast alerts
  enable_service_budgets = false  # Enable per-service budgets
  enable_usage_budget = false  # Enable usage budget
  enabled = true  # Enable this resource
  forecast_threshold = 100  # Forecast alert threshold (%)
  monthly_amount = 1000  # Monthly budget limit (USD)
  notification_comparison = "GREATER_THAN"  # Notification Comparison
  notification_threshold_type = "PERCENTAGE"  # Notification Threshold Type
  notification_type = "ACTUAL"  # Notification Type
  rds_budget_amount = 0  # RDS monthly budget (USD)
  service_alert_threshold = 80  # Service Alert Threshold
}

config_rules = {
  delivery_frequency = "TwentyFour_Hours"  # Delivery Frequency
  enable_cost_rules = true  # Enable Cost Rules
  enable_operational_rules = true  # Enable Operational Rules
  enable_recorder = true  # Enable Recorder
  enable_reliability_rules = true  # Enable Reliability Rules
  enable_security_rules = true  # Enable Security Rules
  enabled = true  # Enable this resource
  excluded_resource_types = []  # Excluded Resource Types
  include_global_resources = true  # Include Global Resources
  min_backup_retention_days = 7  # Min Backup Retention Days
  record_all_resources = true  # Record All Resources
  retention_days = 365  # Retention Days
}

guardduty_enhanced = {
  enable_eks_protection = false  # Enable EKS audit log protection
  enable_malware_protection = true  # Enable EBS malware protection
  enable_s3_export = true  # Enable findings export to S3
  enabled = false  # Enable this resource
  findings_retention_days = 365  # Findings retention (days)
  severity_threshold = 7  # Severity Threshold
}
