#------------------------------------------------------------------------------
# Monitoring Configuration - PROD Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-03 17:57:13
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

monitoring = {
  alb_5xx_threshold = 10  # ALB 5xx error alarm threshold
  # ALB p99 latency alarm threshold (seconds)
  alb_latency_threshold = 2.0
  alert_email = "dr-alerts@company.com"  # Alert notification email
  aurora_connections_threshold = 100  # Aurora connections alarm threshold
  aurora_cpu_threshold = 80  # Aurora CPU alarm threshold %
}
