#------------------------------------------------------------------------------
# Monitoring Configuration - TEST Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-03 17:57:13
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

monitoring = {
  alb_5xx_threshold = 20  # ALB 5xx error alarm threshold
  # ALB p99 latency alarm threshold (seconds)
  alb_latency_threshold = 5.0
  alert_email = ""  # Alert notification email
  aurora_connections_threshold = 50  # Aurora connections alarm threshold
  aurora_cpu_threshold = 90  # Aurora CPU alarm threshold %
}
