#------------------------------------------------------------------------------
# IDP Document Processing Module
#------------------------------------------------------------------------------
# Orchestrates Textract OCR and Comprehend NLP for document processing
# Includes Step Functions workflow for async processing pipeline
#
# AI Services Approach:
# This module uses Textract and Comprehend built-in APIs (pay-per-use) via SDK
# calls from Lambda functions. No custom models or endpoints are provisioned.
#
# For solutions requiring custom AI models, see:
# - modules/aws/comprehend - Custom document classifiers, entity recognizers, flywheels
# - modules/aws/textract - Custom adapters for domain-specific layouts, query templates
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"

  # AI services are resolved with defaults via the variable's optional() declarations
  textract   = var.ai_services.textract
  comprehend = var.ai_services.comprehend
}

#------------------------------------------------------------------------------
# Document Processing Lambda Functions
#------------------------------------------------------------------------------
# Lambda: Start document analysis (triggers Textract)
module "lambda_start_analysis" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-start-analysis"
  description   = "Starts Textract document analysis"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.start_analysis
  source_code_hash = var.lambda.source_hashes.start_analysis

  environment_variables = {
    DOCUMENTS_BUCKET = var.storage.documents_bucket_name
    RESULTS_TABLE    = var.storage.results_table_name
    SNS_TOPIC_ARN    = aws_sns_topic.textract_notifications.arn
    TEXTRACT_ROLE    = aws_iam_role.textract.arn
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Process Textract results
module "lambda_process_textract" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-process-textract"
  description   = "Processes Textract results and extracts structured data"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 300
  memory_size   = 1024

  filename         = var.lambda.packages.process_textract
  source_code_hash = var.lambda.source_hashes.process_textract

  environment_variables = {
    DOCUMENTS_BUCKET = var.storage.documents_bucket_name
    RESULTS_TABLE    = var.storage.results_table_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Comprehend NLP analysis
module "lambda_comprehend_analysis" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-comprehend-analysis"
  description   = "Runs Comprehend NLP analysis on extracted text"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 300
  memory_size   = 512

  filename         = var.lambda.packages.comprehend_analysis
  source_code_hash = var.lambda.source_hashes.comprehend_analysis

  environment_variables = {
    DOCUMENTS_BUCKET   = var.storage.documents_bucket_name
    RESULTS_TABLE      = var.storage.results_table_name
    ENABLE_PII         = tostring(local.comprehend.enable_pii_detection)
    ENABLE_ENTITIES    = tostring(local.comprehend.enable_entity_detection)
    ENABLE_KEY_PHRASES = tostring(local.comprehend.enable_key_phrases)
    ENABLE_SENTIMENT   = tostring(local.comprehend.enable_sentiment)
    LANGUAGE_CODE      = local.comprehend.language_code
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Validate and classify document
module "lambda_validate_document" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-validate-document"
  description   = "Validates document type and determines processing path"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.validate_document
  source_code_hash = var.lambda.source_hashes.validate_document

  environment_variables = {
    DOCUMENTS_BUCKET     = var.storage.documents_bucket_name
    RESULTS_TABLE        = var.storage.results_table_name
    SUPPORTED_TYPES      = join(",", local.textract.supported_document_types)
    MAX_FILE_SIZE_MB     = tostring(local.textract.max_file_size_mb)
    CONFIDENCE_THRESHOLD = tostring(local.textract.confidence_threshold)
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda: Aggregate and finalize results
module "lambda_finalize_results" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-finalize-results"
  description   = "Aggregates results and updates final document status"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.finalize_results
  source_code_hash = var.lambda.source_hashes.finalize_results

  environment_variables = {
    DOCUMENTS_BUCKET = var.storage.documents_bucket_name
    RESULTS_TABLE    = var.storage.results_table_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# SNS Topic for Textract Async Notifications
#------------------------------------------------------------------------------
resource "aws_sns_topic" "textract_notifications" {
  name              = "${local.name_prefix}-textract-notifications"
  kms_master_key_id = var.kms_key_arn

  tags = var.common_tags
}

resource "aws_sns_topic_policy" "textract_notifications" {
  arn = aws_sns_topic.textract_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTextractPublish"
        Effect = "Allow"
        Principal = {
          Service = "textract.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.textract_notifications.arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# IAM Role for Textract Service
#------------------------------------------------------------------------------
resource "aws_iam_role" "textract" {
  name = "${local.name_prefix}-textract-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "textract.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "textract_s3" {
  name = "${local.name_prefix}-textract-s3"
  role = aws_iam_role.textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${var.storage.documents_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "textract_sns" {
  name = "${local.name_prefix}-textract-sns"
  role = aws_iam_role.textract.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.textract_notifications.arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Lambda IAM Policies for AWS AI Services
#------------------------------------------------------------------------------
# Textract permissions for Lambda functions
resource "aws_iam_role_policy" "lambda_textract" {
  for_each = toset([
    module.lambda_start_analysis.role_name,
    module.lambda_process_textract.role_name
  ])

  name = "textract-access"
  role = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "textract:StartDocumentTextDetection",
          "textract:StartDocumentAnalysis",
          "textract:GetDocumentTextDetection",
          "textract:GetDocumentAnalysis",
          "textract:AnalyzeDocument",
          "textract:DetectDocumentText",
          "textract:AnalyzeExpense",
          "textract:AnalyzeID"
        ]
        Resource = "*"
      }
    ]
  })
}

# Comprehend permissions for Lambda functions
resource "aws_iam_role_policy" "lambda_comprehend" {
  name = "comprehend-access"
  role = module.lambda_comprehend_analysis.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "comprehend:DetectEntities",
          "comprehend:DetectKeyPhrases",
          "comprehend:DetectPiiEntities",
          "comprehend:DetectSentiment",
          "comprehend:ClassifyDocument",
          "comprehend:ContainsPiiEntities"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 permissions for all Lambda functions
resource "aws_iam_role_policy" "lambda_s3" {
  for_each = toset([
    module.lambda_start_analysis.role_name,
    module.lambda_process_textract.role_name,
    module.lambda_comprehend_analysis.role_name,
    module.lambda_validate_document.role_name,
    module.lambda_finalize_results.role_name
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

# DynamoDB permissions for all Lambda functions
resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = toset([
    module.lambda_start_analysis.role_name,
    module.lambda_process_textract.role_name,
    module.lambda_comprehend_analysis.role_name,
    module.lambda_validate_document.role_name,
    module.lambda_finalize_results.role_name
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
          "dynamodb:Query"
        ]
        Resource = [
          var.storage.results_table_arn,
          "${var.storage.results_table_arn}/index/*"
        ]
      }
    ]
  })
}

# SNS publish permission for start analysis Lambda
resource "aws_iam_role_policy" "lambda_sns" {
  name = "sns-publish"
  role = module.lambda_start_analysis.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = aws_sns_topic.textract_notifications.arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Step Functions State Machine
#------------------------------------------------------------------------------
module "step_functions" {
  source = "../aws/step-functions"

  name = "${local.name_prefix}-document-processing"

  definition = jsonencode({
    Comment = "IDP Document Processing Workflow"
    StartAt = "ValidateDocument"
    States = {
      ValidateDocument = {
        Type     = "Task"
        Resource = module.lambda_validate_document.function_arn
        Next     = "CheckValidation"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ProcessingFailed"
          ResultPath  = "$.error"
        }]
      }
      CheckValidation = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.isValid"
          BooleanEquals = true
          Next          = "StartTextractAnalysis"
        }]
        Default = "ValidationFailed"
      }
      StartTextractAnalysis = {
        Type     = "Task"
        Resource = module.lambda_start_analysis.function_arn
        Next     = "WaitForTextract"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ProcessingFailed"
          ResultPath  = "$.error"
        }]
      }
      WaitForTextract = {
        Type    = "Wait"
        Seconds = local.textract.polling_interval_seconds
        Next    = "ProcessTextractResults"
      }
      ProcessTextractResults = {
        Type     = "Task"
        Resource = module.lambda_process_textract.function_arn
        Next     = "CheckTextractComplete"
        Retry = [{
          ErrorEquals     = ["TextractNotReady"]
          IntervalSeconds = local.textract.polling_interval_seconds
          MaxAttempts     = local.textract.max_polling_attempts
          BackoffRate     = 1.5
        }]
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ProcessingFailed"
          ResultPath  = "$.error"
        }]
      }
      CheckTextractComplete = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.textractComplete"
          BooleanEquals = true
          Next          = "RunComprehendAnalysis"
        }]
        Default = "WaitForTextract"
      }
      RunComprehendAnalysis = {
        Type     = "Task"
        Resource = module.lambda_comprehend_analysis.function_arn
        Next     = "CheckHumanReviewRequired"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ProcessingFailed"
          ResultPath  = "$.error"
        }]
      }
      CheckHumanReviewRequired = {
        Type = "Choice"
        Choices = [{
          Variable      = "$.requiresHumanReview"
          BooleanEquals = true
          Next          = "SendToHumanReview"
        }]
        Default = "FinalizeResults"
      }
      SendToHumanReview = {
        Type     = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage"
        Parameters = {
          QueueUrl    = var.human_review != null ? var.human_review.queue_url : null
          MessageBody = {
            "documentId.$" = "$.documentId"
            "results.$"    = "$.results"
          }
        }
        Next = "WaitForHumanReview"
      }
      WaitForHumanReview = {
        Type = "Task"
        Resource = "arn:aws:states:::sqs:sendMessage.waitForTaskToken"
        HeartbeatSeconds = 3600
        Parameters = {
          QueueUrl = var.human_review != null ? var.human_review.queue_url : null
          MessageBody = {
            "taskToken.$" = "$$.Task.Token"
            "documentId.$" = "$.documentId"
          }
        }
        Next  = "FinalizeResults"
        Catch = [{
          ErrorEquals = ["States.Timeout", "States.HeartbeatTimeout"]
          Next        = "HumanReviewTimeout"
        }]
      }
      FinalizeResults = {
        Type     = "Task"
        Resource = module.lambda_finalize_results.function_arn
        Next     = "ProcessingComplete"
        Catch = [{
          ErrorEquals = ["States.ALL"]
          Next        = "ProcessingFailed"
          ResultPath  = "$.error"
        }]
      }
      ProcessingComplete = {
        Type = "Succeed"
      }
      ValidationFailed = {
        Type  = "Fail"
        Error = "ValidationError"
        Cause = "Document validation failed"
      }
      ProcessingFailed = {
        Type  = "Fail"
        Error = "ProcessingError"
        Cause = "Document processing failed"
      }
      HumanReviewTimeout = {
        Type  = "Fail"
        Error = "HumanReviewTimeout"
        Cause = "Human review did not complete in time"
      }
    }
  })

  lambda_arns = [
    module.lambda_validate_document.function_arn,
    module.lambda_start_analysis.function_arn,
    module.lambda_process_textract.function_arn,
    module.lambda_comprehend_analysis.function_arn,
    module.lambda_finalize_results.function_arn
  ]

  dynamodb_table_arns = [var.storage.results_table_arn]
  s3_bucket_arns      = [var.storage.documents_bucket_arn]
  sqs_queue_arns      = var.human_review != null ? [var.human_review.queue_arn] : []

  enable_textract   = true
  enable_comprehend = true

  log_level            = var.logging.step_functions_log_level
  log_retention_days   = var.logging.retention_days
  xray_tracing_enabled = var.monitoring.xray_enabled
  kms_key_arn          = var.kms_key_arn

  common_tags = var.common_tags
}
