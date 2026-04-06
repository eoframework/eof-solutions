#------------------------------------------------------------------------------
# Best Practices Configuration - TEST Environment
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Cost Optimization: AWS Budgets
#------------------------------------------------------------------------------
budget = {
  enabled               = true
  monthly_amount        = 2000
  alert_thresholds      = [80, 100]
  alert_emails          = ["finance@company.com"]
  enable_forecast_alert = true
}

#------------------------------------------------------------------------------
# Operational Excellence: AWS Config Rules
#------------------------------------------------------------------------------
config_rules = {
  enabled                  = false
  enable_recorder          = true
  retention_days           = 365
  enable_security_rules    = true
  enable_reliability_rules = true
  enable_operational_rules = true
  enable_cost_rules        = true
}

#------------------------------------------------------------------------------
# Security: GuardDuty
#------------------------------------------------------------------------------
guardduty = {
  enabled                   = false
  enable_malware_protection = true
  severity_threshold        = 7
}

#------------------------------------------------------------------------------
# Reliability: AWS Backup
#------------------------------------------------------------------------------
backup = {
  enabled             = false
  daily_retention     = 30
  weekly_retention    = 90
  monthly_retention   = 365
  enable_cross_region = false
  enable_vault_lock   = false
}
