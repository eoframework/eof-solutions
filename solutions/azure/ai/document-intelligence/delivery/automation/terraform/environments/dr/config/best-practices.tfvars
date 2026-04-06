#------------------------------------------------------------------------------
# Best Practices Configuration - DR Environment
#------------------------------------------------------------------------------

backup = {
  enabled        = true  # Enable backup in DR region
  retention_days = 30    # Backup retention period in days
}

budget = {
  enabled            = true                   # Enable cost management budget
  monthly_amount     = 1000                   # Monthly budget limit in USD (lower than prod)
  notification_email = "finance@company.com"  # Recipient for budget alerts
  alert_thresholds = {                        # Named thresholds as percentages
    warning  = 50
    critical = 80
    maximum  = 100
  }
}

policy = {
  enable_security_policies    = true  # Enforce Azure security baseline policies
  enable_cost_policies        = true  # Enforce cost management policies
  enable_operational_policies = true  # Enforce operational policies
}
