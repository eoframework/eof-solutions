#------------------------------------------------------------------------------
# Best Practices Configuration - PROD Environment
#------------------------------------------------------------------------------

backup = {
  enabled        = true  # Enable Azure Recovery Services backup
  retention_days = 30    # Backup retention period in days
}

budget = {
  enabled            = true                    # Enable cost management budget
  monthly_amount     = 2000                    # Monthly budget limit in USD
  notification_email = "finance@company.com"   # Recipient for budget alerts
  alert_thresholds = {                         # Named thresholds as percentages
    warning  = 50
    critical = 80
    maximum  = 100
  }
}

policy = {
  enable_security_policies    = true  # Enforce Azure security baseline policies
  enable_cost_policies        = true  # Enforce cost management policies
  enable_operational_policies = true  # Enforce operational policies (tagging etc.)
}
