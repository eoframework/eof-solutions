#------------------------------------------------------------------------------
# Monitoring Configuration - TEST Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-02 11:21:17
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

logging = {
  api_gateway_log_level = "INFO"  # API Gateway log level
  data_trace_enabled = true  # Enable data tracing
  retention_days = 7  # CloudWatch log retention
  step_functions_log_level = "ALL"  # Step Functions log level
}

monitoring = {
  api_4xx_threshold = 200  # API 4xx error threshold
  api_error_threshold = 50  # API 5xx error threshold
  api_latency_p95_ms = 5000  # API p95 latency threshold (ms)
  enable_alarms = false  # Enable CloudWatch alarms
  lambda_duration_p95_ms = 60000  # Lambda p95 duration threshold (ms)
  lambda_error_rate_percent = 10  # Lambda error rate threshold (%)
  sfn_failure_threshold = 20  # Step Functions failure threshold
  sns_topic_arn = null  # SNS topic for alerts
  xray_enabled = true  # Enable X-Ray tracing
}
