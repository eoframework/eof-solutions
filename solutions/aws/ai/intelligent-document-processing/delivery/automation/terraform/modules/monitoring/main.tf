#------------------------------------------------------------------------------
# IDP Monitoring Module
#------------------------------------------------------------------------------
# Centralized CloudWatch alarms for IDP solution monitoring
#------------------------------------------------------------------------------

locals {
  name_prefix   = "${var.project.name}-${var.project.environment}"
  enabled       = var.monitoring.enabled
  sns_actions   = var.monitoring.sns_topic_arn != null ? [var.monitoring.sns_topic_arn] : []
}

#------------------------------------------------------------------------------
# API Gateway Alarms
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  count = local.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.monitoring.api_error_threshold
  alarm_description   = "API Gateway 5XX errors exceeded threshold"
  alarm_actions       = local.sns_actions
  tags                = var.common_tags

  dimensions = {
    ApiName = var.resources.api_id
    Stage   = var.resources.api_stage
  }
}

resource "aws_cloudwatch_metric_alarm" "api_4xx_errors" {
  count = local.enabled && var.monitoring.api_4xx_threshold != null ? 1 : 0

  alarm_name          = "${local.name_prefix}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = var.monitoring.api_4xx_threshold
  alarm_description   = "API Gateway 4XX errors exceeded threshold"
  alarm_actions       = local.sns_actions
  tags                = var.common_tags

  dimensions = {
    ApiName = var.resources.api_id
    Stage   = var.resources.api_stage
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  count = local.enabled && var.monitoring.api_latency_p95_ms != null ? 1 : 0

  alarm_name          = "${local.name_prefix}-api-latency-p95"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 300
  extended_statistic  = "p95"
  threshold           = var.monitoring.api_latency_p95_ms
  alarm_description   = "API Gateway P95 latency exceeded threshold"
  alarm_actions       = local.sns_actions
  tags                = var.common_tags

  dimensions = {
    ApiName = var.resources.api_id
    Stage   = var.resources.api_stage
  }
}

#------------------------------------------------------------------------------
# Step Functions Alarms
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "sfn_failed_executions" {
  count = local.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-sfn-failed-executions"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ExecutionsFailed"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = var.monitoring.sfn_failure_threshold
  alarm_description   = "Step Functions execution failures exceeded threshold"
  alarm_actions       = local.sns_actions
  tags                = var.common_tags

  dimensions = {
    StateMachineArn = var.resources.state_machine_arn
  }
}

resource "aws_cloudwatch_metric_alarm" "sfn_throttled" {
  count = local.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-sfn-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ExecutionsThrottled"
  namespace           = "AWS/States"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Step Functions executions are being throttled"
  alarm_actions       = local.sns_actions
  tags                = var.common_tags

  dimensions = {
    StateMachineArn = var.resources.state_machine_arn
  }
}
