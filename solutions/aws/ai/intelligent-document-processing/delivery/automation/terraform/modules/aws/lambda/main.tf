#------------------------------------------------------------------------------
# AWS Lambda Function Module
#------------------------------------------------------------------------------
# Creates Lambda functions for serverless compute
# Supports: layers, environment variables, VPC configuration, X-Ray tracing
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# IAM Role for Lambda Execution
#------------------------------------------------------------------------------
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Basic execution role policy (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution role policy (if VPC enabled)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.vpc_subnet_ids != null ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing policy
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count = var.tracing_mode == "Active" ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

#------------------------------------------------------------------------------
# Lambda Function
#------------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Graviton2 (arm64) by default — 20% cheaper per GB-second, same performance for Python/Node
  architectures = var.architectures

  # Code source - either S3 or local zip
  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version
  filename          = var.filename
  source_code_hash  = var.source_code_hash

  # Layers
  layers = var.layers

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration (optional)
  dynamic "vpc_config" {
    for_each = var.vpc_subnet_ids != null ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  # X-Ray tracing
  tracing_config {
    mode = var.tracing_mode
  }

  # Structured JSON logging with configurable log level (Provider 5+)
  logging_config {
    log_format = var.log_format
    log_level  = var.log_format == "JSON" ? var.log_level : null
    log_group  = aws_cloudwatch_log_group.this.name
  }

  # Reserved concurrency (optional)
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # Dead letter queue (optional)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  # KMS encryption for environment variables
  kms_key_arn = var.kms_key_arn

  tags = merge(var.common_tags, {
    Name = var.function_name
  })

  depends_on = [aws_cloudwatch_log_group.this]
}

#------------------------------------------------------------------------------
# CloudWatch Log Group (created before Lambda to control retention)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Lambda Permission (for triggers like S3, API Gateway, etc.)
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "triggers" {
  for_each = var.permissions

  statement_id  = each.key
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = each.value.principal
  source_arn    = each.value.source_arn
}

#------------------------------------------------------------------------------
# Provisioned Concurrency (optional)
#------------------------------------------------------------------------------
resource "aws_lambda_provisioned_concurrency_config" "this" {
  count = var.provisioned_concurrent_executions > 0 ? 1 : 0

  function_name                     = aws_lambda_function.this.function_name
  provisioned_concurrent_executions = var.provisioned_concurrent_executions
  qualifier                         = aws_lambda_function.this.version
}

#------------------------------------------------------------------------------
# Event Source Mappings (for SQS, DynamoDB Streams, etc.)
#------------------------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "this" {
  for_each = var.event_source_mappings

  event_source_arn  = each.value.event_source_arn
  function_name     = aws_lambda_function.this.arn
  starting_position = lookup(each.value, "starting_position", null)
  batch_size        = lookup(each.value, "batch_size", 10)
  enabled           = lookup(each.value, "enabled", true)

  dynamic "filter_criteria" {
    for_each = lookup(each.value, "filter_pattern", null) != null ? [1] : []
    content {
      filter {
        pattern = each.value.filter_pattern
      }
    }
  }
}
