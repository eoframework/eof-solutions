#------------------------------------------------------------------------------
# IDP Document Processing Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Step Functions
#------------------------------------------------------------------------------

output "state_machine_arn" {
  description = "ARN of the document processing state machine"
  value       = module.step_functions.state_machine_arn
}

output "state_machine_name" {
  description = "Name of the document processing state machine"
  value       = module.step_functions.state_machine_name
}

#------------------------------------------------------------------------------
# Lambda Functions
#------------------------------------------------------------------------------

output "lambda_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    validate_document   = module.lambda_validate_document.function_arn
    start_analysis      = module.lambda_start_analysis.function_arn
    process_textract    = module.lambda_process_textract.function_arn
    comprehend_analysis = module.lambda_comprehend_analysis.function_arn
    finalize_results    = module.lambda_finalize_results.function_arn
  }
}

output "lambda_invoke_arns" {
  description = "Map of Lambda function invoke ARNs (for API Gateway)"
  value = {
    validate_document   = module.lambda_validate_document.invoke_arn
    start_analysis      = module.lambda_start_analysis.invoke_arn
    process_textract    = module.lambda_process_textract.invoke_arn
    comprehend_analysis = module.lambda_comprehend_analysis.invoke_arn
    finalize_results    = module.lambda_finalize_results.invoke_arn
  }
}

output "lambda_role_arns" {
  description = "Map of Lambda function IAM role ARNs"
  value = {
    validate_document   = module.lambda_validate_document.role_arn
    start_analysis      = module.lambda_start_analysis.role_arn
    process_textract    = module.lambda_process_textract.role_arn
    comprehend_analysis = module.lambda_comprehend_analysis.role_arn
    finalize_results    = module.lambda_finalize_results.role_arn
  }
}

#------------------------------------------------------------------------------
# SNS Topic
#------------------------------------------------------------------------------

output "textract_notifications_topic_arn" {
  description = "ARN of the Textract notifications SNS topic"
  value       = aws_sns_topic.textract_notifications.arn
}

#------------------------------------------------------------------------------
# IAM Roles
#------------------------------------------------------------------------------

output "textract_role_arn" {
  description = "ARN of the Textract service role"
  value       = aws_iam_role.textract.arn
}
