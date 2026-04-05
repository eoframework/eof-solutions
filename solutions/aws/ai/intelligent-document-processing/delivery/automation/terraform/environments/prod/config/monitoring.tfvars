#------------------------------------------------------------------------------
# Monitoring Configuration - PROD Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-02 00:00:41
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

logging = {
  api_gateway_log_level    = "INFO"  # API Gateway log level
  data_trace_enabled       = false   # Enable data tracing
  retention_days           = 30      # CloudWatch log retention
  step_functions_log_level = "ERROR" # Step Functions log level
}

monitoring = {
  api_4xx_threshold         = 100   # API 4xx error threshold
  api_error_threshold       = 10    # API 5xx error threshold
  api_latency_p95_ms        = 2000  # API p95 latency threshold (ms)
  enable_alarms             = true  # Enable CloudWatch alarms
  lambda_duration_p95_ms    = 60000 # Lambda p95 duration threshold (ms)
  lambda_error_rate_percent = 5     # Lambda error rate threshold (%)
  sfn_failure_threshold     = 5     # Step Functions failure threshold
  sns_topic_arn             = null  # SNS topic ARN - required when enable_alarms = true
  xray_enabled              = true  # Enable X-Ray tracing
}
