#------------------------------------------------------------------------------
# Best Practices Configuration - DR Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-02 11:50:18
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

budget = {
  # [Cost Optimization] Alert email addresses
  alert_emails = []
  # [Cost Optimization] Budget alert thresholds (%)
  alert_thresholds = [50, 80, 100]
  # [Cost Optimization] Enable forecasted spend alerts
  enable_forecast_alert = true
  # [Cost Optimization] Enable AWS Budgets tracking
  enabled = true
  # [Cost Optimization] Monthly budget limit (USD)
  monthly_amount = 1500
}

config_rules = {
  # [Operational Excellence] Enable Config recorder
  enable_recorder = true
  # [Operational Excellence] Enable reliability compliance rules
  enable_reliability_rules = true
  # [Operational Excellence] Enable security compliance rules
  enable_security_rules = true
  # [Operational Excellence] Enable AWS Config rules
  enabled = true
  # [Operational Excellence] Config history retention (days)
  retention_days = 365
}

guardduty = {
  enable_malware_protection = true  # [Security] Enable S3 malware protection
  # [Security] Enable S3 data event monitoring
  enable_s3_protection = true
  # [Security] Enable GuardDuty threat detection
  enabled = true
  # [Security] Minimum alert severity threshold (1-10)
  severity_threshold = 7
}
