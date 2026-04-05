#------------------------------------------------------------------------------
# IDP API Module
#------------------------------------------------------------------------------
# Creates REST API with Lambda backends for IDP operations
# Includes endpoints for document upload, status, results, and management
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

#------------------------------------------------------------------------------
# API Lambda Functions
#------------------------------------------------------------------------------
# Lambda: Upload document
module "lambda_upload" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-upload"
  description   = "Handles document upload requests"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda.packages.api_upload
  source_code_hash = var.lambda.source_hashes.api_upload

  environment_variables = {
    DOCUMENTS_BUCKET      = var.storage.documents_bucket_name
    RESULTS_TABLE         = var.storage.results_table_name
    STATE_MACHINE_ARN     = var.state_machine_arn
    MAX_FILE_SIZE_MB      = tostring(var.api.max_file_size_mb)
    ALLOWED_CONTENT_TYPES = join(",", var.api.allowed_content_types)
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Get document status
module "lambda_status" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-status"
  description   = "Returns document processing status"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 10
  memory_size   = 128

  filename         = var.lambda.packages.api_status
  source_code_hash = var.lambda.source_hashes.api_status

  environment_variables = {
    RESULTS_TABLE = var.storage.results_table_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Get document results
module "lambda_results" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-results"
  description   = "Returns processed document results"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda.packages.api_results
  source_code_hash = var.lambda.source_hashes.api_results

  environment_variables = {
    RESULTS_TABLE    = var.storage.results_table_name
    DOCUMENTS_BUCKET = var.storage.documents_bucket_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: List documents
module "lambda_list" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-list"
  description   = "Lists documents with pagination and filtering"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda.packages.api_list
  source_code_hash = var.lambda.source_hashes.api_list

  environment_variables = {
    RESULTS_TABLE = var.storage.results_table_name
    PAGE_SIZE     = tostring(var.api.default_page_size)
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Delete document
module "lambda_delete" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-delete"
  description   = "Deletes document and associated data"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 30
  memory_size   = 256

  filename         = var.lambda.packages.api_delete
  source_code_hash = var.lambda.source_hashes.api_delete

  environment_variables = {
    RESULTS_TABLE    = var.storage.results_table_name
    DOCUMENTS_BUCKET = var.storage.documents_bucket_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Health check
module "lambda_health" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-api-health"
  description   = "API health check endpoint"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 5
  memory_size   = 128

  filename         = var.lambda.packages.api_health
  source_code_hash = var.lambda.source_hashes.api_health

  environment_variables = {
    VERSION = var.api.version
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# IAM Policies for Lambda Functions
#------------------------------------------------------------------------------
# S3 access for upload/results/delete Lambda
resource "aws_iam_role_policy" "lambda_s3" {
  for_each = toset([
    module.lambda_upload.role_name,
    module.lambda_results.role_name,
    module.lambda_delete.role_name
  ])

  name = "s3-access"
  role = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${var.storage.documents_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = var.storage.documents_bucket_arn
      }
    ]
  })
}

# DynamoDB access for all API Lambda functions
resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = toset([
    module.lambda_upload.role_name,
    module.lambda_status.role_name,
    module.lambda_results.role_name,
    module.lambda_list.role_name,
    module.lambda_delete.role_name
  ])

  name = "dynamodb-access"
  role = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          var.storage.results_table_arn,
          "${var.storage.results_table_arn}/index/*"
        ]
      }
    ]
  })
}

# Step Functions access for upload Lambda
resource "aws_iam_role_policy" "lambda_sfn" {
  name = "step-functions-access"
  role = module.lambda_upload.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "states:StartExecution"
        Resource = var.state_machine_arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# API Gateway
#------------------------------------------------------------------------------
module "api_gateway" {
  source = "../aws/api-gateway"

  api_name    = "${local.name_prefix}-api"
  description = "IDP REST API for document processing"

  endpoint_type = var.api.endpoint_type
  stage_name    = var.api.stage_name

  binary_media_types = var.api.allowed_content_types

  # API Resources (paths)
  resources = {
    documents = {
      parent_path = "/"
      path_part   = "documents"
    }
    document_id = {
      parent_path = "documents"
      path_part   = "{documentId}"
    }
    document_status = {
      parent_path = "document_id"
      path_part   = "status"
    }
    document_results = {
      parent_path = "document_id"
      path_part   = "results"
    }
    health = {
      parent_path = "/"
      path_part   = "health"
    }
  }

  # API Methods
  methods = {
    # POST /documents - Upload document
    upload_document = {
      resource_path     = "documents"
      http_method       = "POST"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_upload.invoke_arn
    }
    # GET /documents - List documents
    list_documents = {
      resource_path     = "documents"
      http_method       = "GET"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_list.invoke_arn
      request_parameters = {
        "method.request.querystring.status"    = false
        "method.request.querystring.pageToken" = false
        "method.request.querystring.pageSize"  = false
      }
    }
    # GET /documents/{documentId} - Get document details
    get_document = {
      resource_path     = "document_id"
      http_method       = "GET"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_results.invoke_arn
    }
    # DELETE /documents/{documentId} - Delete document
    delete_document = {
      resource_path     = "document_id"
      http_method       = "DELETE"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_delete.invoke_arn
    }
    # GET /documents/{documentId}/status - Get processing status
    get_status = {
      resource_path     = "document_status"
      http_method       = "GET"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_status.invoke_arn
    }
    # GET /documents/{documentId}/results - Get processing results
    get_results = {
      resource_path     = "document_results"
      http_method       = "GET"
      authorization     = var.cognito_user_pool_arn != null ? "COGNITO_USER_POOLS" : "NONE"
      lambda_invoke_arn = module.lambda_results.invoke_arn
    }
    # GET /health - Health check
    health_check = {
      resource_path     = "health"
      http_method       = "GET"
      authorization     = "NONE"
      lambda_invoke_arn = module.lambda_health.invoke_arn
    }
  }

  enable_cors = var.api.enable_cors

  cognito_user_pool_arn = var.cognito_user_pool_arn

  throttling_burst_limit = var.api.throttling_burst_limit
  throttling_rate_limit  = var.api.throttling_rate_limit

  log_retention_days   = var.logging.retention_days
  logging_level        = var.logging.api_gateway_log_level
  data_trace_enabled   = var.logging.data_trace_enabled
  xray_tracing_enabled = var.monitoring.xray_enabled

  kms_key_arn = var.kms_key_arn

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Lambda Permissions for API Gateway
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "api_gateway" {
  for_each = {
    upload  = module.lambda_upload.function_name
    status  = module.lambda_status.function_name
    results = module.lambda_results.function_name
    list    = module.lambda_list.function_name
    delete  = module.lambda_delete.function_name
    health  = module.lambda_health.function_name
  }

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}
