#------------------------------------------------------------------------------
# IDP Human Review Module
#------------------------------------------------------------------------------
# Implements Amazon A2I (Augmented AI) workflow for human review of
# low-confidence document processing results
#------------------------------------------------------------------------------

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"

  # SSM parameter path for Step Functions ARN (populated by main.tf after document_processing is created)
  ssm_step_functions_arn_path = "/${var.project.name}/${var.project.environment}/step-functions/document-processing-arn"
}

#------------------------------------------------------------------------------
# SQS Queue for Human Review Tasks
#------------------------------------------------------------------------------
module "review_queue" {
  source = "../aws/sqs"

  queue_name                 = "${local.name_prefix}-human-review"
  visibility_timeout_seconds = var.queue.visibility_timeout
  message_retention_seconds  = var.queue.message_retention
  receive_wait_time_seconds  = var.queue.receive_wait_time
  delay_seconds              = 0

  create_dlq        = true
  max_receive_count = var.queue.max_receive_count

  kms_key_arn = var.kms_key_arn

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Lambda: Process Human Review Results
#------------------------------------------------------------------------------
module "lambda_process_review" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-process-review"
  description   = "Processes completed human review results"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.process_review
  source_code_hash = var.lambda.source_hashes.process_review

  environment_variables = {
    RESULTS_TABLE                = var.storage.results_table_name
    DOCUMENTS_BUCKET             = var.storage.documents_bucket_name
    SSM_STEP_FUNCTIONS_ARN_PATH  = local.ssm_step_functions_arn_path
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

# Lambda SQS trigger
resource "aws_lambda_event_source_mapping" "review_queue" {
  event_source_arn = module.review_queue.queue_arn
  function_name    = module.lambda_process_review.function_arn
  batch_size       = 1
  enabled          = true
}

#------------------------------------------------------------------------------
# Lambda: Create Human Review Task
#------------------------------------------------------------------------------
module "lambda_create_task" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-create-review-task"
  description   = "Creates human review task in A2I"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.create_task
  source_code_hash = var.lambda.source_hashes.create_task

  environment_variables = {
    RESULTS_TABLE          = var.storage.results_table_name
    DOCUMENTS_BUCKET       = var.storage.documents_bucket_name
    FLOW_DEFINITION_ARN    = var.a2i.use_private_workforce ? aws_sagemaker_flow_definition.private[0].arn : aws_sagemaker_flow_definition.public[0].arn
    CONFIDENCE_THRESHOLD   = tostring(var.a2i.confidence_threshold)
    TASK_DESCRIPTION       = var.a2i.task_description
    TASK_TITLE             = var.a2i.task_title
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Lambda: Complete Step Functions Task
#------------------------------------------------------------------------------
module "lambda_complete_task" {
  source = "../aws/lambda"

  function_name = "${local.name_prefix}-complete-sfn-task"
  description   = "Completes Step Functions task token after human review"
  handler       = "index.handler"
  runtime       = var.lambda.runtime
  timeout       = 60
  memory_size   = 256

  filename         = var.lambda.packages.complete_task
  source_code_hash = var.lambda.source_hashes.complete_task

  environment_variables = {
    RESULTS_TABLE = var.storage.results_table_name
  }

  vpc_subnet_ids         = var.vpc.subnet_ids
  vpc_security_group_ids = var.vpc.security_group_ids

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# IAM Policies for Lambda Functions
#------------------------------------------------------------------------------
# S3 access
resource "aws_iam_role_policy" "lambda_s3" {
  for_each = toset([
    module.lambda_process_review.role_name,
    module.lambda_create_task.role_name,
    module.lambda_complete_task.role_name
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
          "s3:PutObject"
        ]
        Resource = "${var.storage.documents_bucket_arn}/*"
      }
    ]
  })
}

# DynamoDB access
resource "aws_iam_role_policy" "lambda_dynamodb" {
  for_each = toset([
    module.lambda_process_review.role_name,
    module.lambda_create_task.role_name,
    module.lambda_complete_task.role_name
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

# Step Functions access for completing task tokens
# Uses wildcard for state machines in this account/region since ARN is resolved at runtime via SSM
resource "aws_iam_role_policy" "lambda_sfn" {
  for_each = toset([
    module.lambda_complete_task.role_name,
    module.lambda_process_review.role_name
  ])

  name = "step-functions-access"
  role = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:SendTaskSuccess",
          "states:SendTaskFailure",
          "states:SendTaskHeartbeat"
        ]
        Resource = "arn:aws:states:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:stateMachine:${local.name_prefix}-*"
      }
    ]
  })
}

# SSM Parameter Store access for reading Step Functions ARN
resource "aws_iam_role_policy" "lambda_ssm" {
  for_each = toset([
    module.lambda_process_review.role_name
  ])

  name = "ssm-access"
  role = each.value

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_step_functions_arn_path}"
      }
    ]
  })
}

# A2I access
resource "aws_iam_role_policy" "lambda_a2i" {
  name = "a2i-access"
  role = module.lambda_create_task.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:StartHumanLoop",
          "sagemaker:StopHumanLoop",
          "sagemaker:DescribeHumanLoop"
        ]
        Resource = "*"
      }
    ]
  })
}

# SQS access for process review Lambda
resource "aws_iam_role_policy" "lambda_sqs" {
  name = "sqs-access"
  role = module.lambda_process_review.role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = module.review_queue.queue_arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# A2I Flow Definition - Private Workforce
#------------------------------------------------------------------------------
resource "aws_sagemaker_flow_definition" "private" {
  count = var.a2i.use_private_workforce ? 1 : 0

  flow_definition_name = "${local.name_prefix}-document-review"

  human_loop_config {
    human_task_ui_arn                     = aws_sagemaker_human_task_ui.this.arn
    task_availability_lifetime_in_seconds = var.a2i.task_availability_seconds
    task_count                            = var.a2i.task_count
    task_description                      = var.a2i.task_description
    task_title                            = var.a2i.task_title
    workteam_arn                          = var.a2i.workteam_arn
  }

  output_config {
    s3_output_path = "s3://${var.storage.documents_bucket_name}/human-review-output/"
    kms_key_id     = var.kms_key_arn
  }

  role_arn = aws_iam_role.a2i.arn

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# A2I Flow Definition - Public Workforce (MTurk)
#------------------------------------------------------------------------------
resource "aws_sagemaker_flow_definition" "public" {
  count = var.a2i.use_private_workforce ? 0 : 1

  flow_definition_name = "${local.name_prefix}-document-review"

  human_loop_config {
    human_task_ui_arn                     = aws_sagemaker_human_task_ui.this.arn
    task_availability_lifetime_in_seconds = var.a2i.task_availability_seconds
    task_count                            = var.a2i.task_count
    task_description                      = var.a2i.task_description
    task_title                            = var.a2i.task_title
    # Public workforce (MTurk) - use the public workforce ARN
    workteam_arn                          = "arn:aws:sagemaker:${data.aws_region.current.id}:394669845002:workteam/public-crowd/default"

    public_workforce_task_price {
      amount_in_usd {
        dollars = floor(var.a2i.task_price_usd)
        cents   = floor((var.a2i.task_price_usd - floor(var.a2i.task_price_usd)) * 100)
      }
    }
  }

  output_config {
    s3_output_path = "s3://${var.storage.documents_bucket_name}/human-review-output/"
    kms_key_id     = var.kms_key_arn
  }

  role_arn = aws_iam_role.a2i.arn

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# A2I Human Task UI (Worker Interface)
#------------------------------------------------------------------------------
resource "aws_sagemaker_human_task_ui" "this" {
  human_task_ui_name = "${local.name_prefix}-document-review-ui"

  ui_template {
    content = var.a2i.custom_ui_template != null ? var.a2i.custom_ui_template : <<-EOF
<script src="https://assets.crowd.aws/crowd-html-elements.js"></script>
<crowd-form>
  <div>
    <h2>Document Review Task</h2>
    <p>{{ task.input.taskDescription }}</p>

    <h3>Document Information</h3>
    <p><strong>Document ID:</strong> {{ task.input.documentId }}</p>
    <p><strong>Confidence Score:</strong> {{ task.input.confidenceScore }}%</p>

    <h3>Extracted Data</h3>
    <div style="background: #f5f5f5; padding: 10px; border-radius: 4px;">
      <pre>{{ task.input.extractedData | tojson(indent=2) }}</pre>
    </div>

    <h3>Review Actions</h3>
    <crowd-radio-group name="reviewDecision">
      <crowd-radio-button value="approve">Approve - Data is correct</crowd-radio-button>
      <crowd-radio-button value="reject">Reject - Data is incorrect</crowd-radio-button>
      <crowd-radio-button value="modify">Modify - Corrections needed</crowd-radio-button>
    </crowd-radio-group>

    <h3>Corrections (if any)</h3>
    <crowd-text-area name="corrections" placeholder="Enter any corrections or notes here..."></crowd-text-area>

    <h3>Confidence in Decision</h3>
    <crowd-slider name="reviewerConfidence" min="0" max="100" step="10" pin>
    </crowd-slider>
  </div>
</crowd-form>
EOF
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# IAM Role for A2I
#------------------------------------------------------------------------------
resource "aws_iam_role" "a2i" {
  name = "${local.name_prefix}-a2i-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "a2i_s3" {
  name = "s3-access"
  role = aws_iam_role.a2i.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
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

resource "aws_iam_role_policy" "a2i_kms" {
  count = var.kms_key_arn != null ? 1 : 0

  name = "kms-access"
  role = aws_iam_role.a2i.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.kms_key_arn
      }
    ]
  })
}

#------------------------------------------------------------------------------
# SNS Topic for A2I Notifications
#------------------------------------------------------------------------------
resource "aws_sns_topic" "a2i_notifications" {
  name              = "${local.name_prefix}-a2i-notifications"
  kms_master_key_id = var.kms_key_arn

  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "a2i_lambda" {
  topic_arn = aws_sns_topic.a2i_notifications.arn
  protocol  = "lambda"
  endpoint  = module.lambda_complete_task.function_arn
}

resource "aws_lambda_permission" "sns_invoke" {
  statement_id  = "AllowSNSInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_complete_task.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.a2i_notifications.arn
}
