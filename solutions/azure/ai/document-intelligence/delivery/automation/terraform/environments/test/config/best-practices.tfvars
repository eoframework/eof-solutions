#------------------------------------------------------------------------------
# Best Practices Configuration - TEST Environment
#------------------------------------------------------------------------------

backup = {
  enabled        = false  # Backup disabled in test to reduce cost
  retention_days = 7      # Backup retention period in days
}

budget = {
  enabled            = true                      # Enable cost management budget
  monthly_amount     = 500                       # Monthly budget limit in USD
  notification_email = "dev-team@company.com"    # Recipient for budget alerts
  alert_thresholds = {                           # Named thresholds as percentages
    critical = 80
    maximum  = 100
  }
}

policy = {
  enable_security_policies    = false  # Security policies disabled in test
  enable_cost_policies        = true   # Enforce cost management policies
  enable_operational_policies = false  # Operational policies disabled in test
}
