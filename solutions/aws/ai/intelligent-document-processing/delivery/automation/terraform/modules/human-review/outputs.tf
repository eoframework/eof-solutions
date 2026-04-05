#------------------------------------------------------------------------------
# IDP Human Review Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SQS Queue
#------------------------------------------------------------------------------

output "review_queue_url" {
  description = "URL of the human review SQS queue"
  value       = module.review_queue.queue_url
}

output "review_queue_arn" {
  description = "ARN of the human review SQS queue"
  value       = module.review_queue.queue_arn
}

output "review_dlq_url" {
  description = "URL of the human review dead-letter queue"
  value       = module.review_queue.dlq_url
}

output "review_dlq_arn" {
  description = "ARN of the human review dead-letter queue"
  value       = module.review_queue.dlq_arn
}

#------------------------------------------------------------------------------
# A2I Flow Definition
#------------------------------------------------------------------------------

output "flow_definition_arn" {
  description = "ARN of the A2I flow definition"
  value       = var.a2i.use_private_workforce ? aws_sagemaker_flow_definition.private[0].arn : aws_sagemaker_flow_definition.public[0].arn
}

output "flow_definition_name" {
  description = "Name of the A2I flow definition"
  value       = var.a2i.use_private_workforce ? aws_sagemaker_flow_definition.private[0].flow_definition_name : aws_sagemaker_flow_definition.public[0].flow_definition_name
}

output "human_task_ui_arn" {
  description = "ARN of the A2I human task UI"
  value       = aws_sagemaker_human_task_ui.this.arn
}

#------------------------------------------------------------------------------
# Lambda Functions
#------------------------------------------------------------------------------

output "lambda_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    process_review = module.lambda_process_review.function_arn
    create_task    = module.lambda_create_task.function_arn
    complete_task  = module.lambda_complete_task.function_arn
  }
}

#------------------------------------------------------------------------------
# SNS Topic
#------------------------------------------------------------------------------

output "notifications_topic_arn" {
  description = "ARN of the A2I notifications SNS topic"
  value       = aws_sns_topic.a2i_notifications.arn
}

#------------------------------------------------------------------------------
# IAM Roles
#------------------------------------------------------------------------------

output "a2i_role_arn" {
  description = "ARN of the A2I execution role"
  value       = aws_iam_role.a2i.arn
}

#------------------------------------------------------------------------------
# Consolidated Outputs (for passing to other modules)
#------------------------------------------------------------------------------

output "outputs" {
  description = "Consolidated outputs for passing to document_processing module"
  value = {
    queue_url = module.review_queue.queue_url
    queue_arn = module.review_queue.queue_arn
  }
}

#------------------------------------------------------------------------------
# SSM Parameter Path (for wiring Step Functions ARN after creation)
#------------------------------------------------------------------------------

output "ssm_step_functions_arn_path" {
  description = "SSM parameter path where Step Functions ARN should be stored"
  value       = local.ssm_step_functions_arn_path
}
