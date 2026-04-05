#------------------------------------------------------------------------------
# IDP Production Environment Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Naming & Identity
#------------------------------------------------------------------------------

output "environment" {
  description = "Environment identifier"
  value       = var.env
}

output "environment_display" {
  description = "Environment display name"
  value = lookup(
    { prod = "Production", test = "Test", dr = "Disaster Recovery" },
    var.env,
    var.env
  )
}

output "name_prefix" {
  description = "Resource naming prefix"
  value       = local.name_prefix
}

output "solution_name" {
  description = "Solution name"
  value       = var.solution.name
}

output "solution_abbr" {
  description = "Solution abbreviation"
  value       = var.solution.abbr
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

#------------------------------------------------------------------------------
# Security Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = module.security.kms_key_arn
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = module.security.kms_alias_arn
}

#------------------------------------------------------------------------------
# Storage Module Outputs
#------------------------------------------------------------------------------

output "documents_bucket_name" {
  description = "Documents S3 bucket name"
  value       = module.storage.documents_bucket_name
}

output "documents_bucket_arn" {
  description = "Documents S3 bucket ARN"
  value       = module.storage.documents_bucket_arn
}

output "output_bucket_name" {
  description = "Output S3 bucket name (for processed results export)"
  value       = module.storage.output_bucket_name
}

output "results_table_name" {
  description = "DynamoDB results table name"
  value       = module.storage.results_table_name
}

output "results_table_arn" {
  description = "DynamoDB results table ARN"
  value       = module.storage.results_table_arn
}

output "jobs_table_name" {
  description = "DynamoDB processing jobs table name"
  value       = module.storage.jobs_table_name
}

#------------------------------------------------------------------------------
# Document Processing Module Outputs
#------------------------------------------------------------------------------

output "document_processing_state_machine_arn" {
  description = "Document processing Step Functions state machine ARN"
  value       = module.document_processing.state_machine_arn
}

output "document_processing_state_machine_name" {
  description = "Document processing Step Functions state machine name"
  value       = module.document_processing.state_machine_name
}

output "document_processing_lambda_arns" {
  description = "Document processing Lambda function ARNs"
  value       = module.document_processing.lambda_arns
}

output "textract_notifications_topic_arn" {
  description = "SNS topic ARN for Textract async notifications"
  value       = module.document_processing.textract_notifications_topic_arn
}

#------------------------------------------------------------------------------
# Human Review Module Outputs
#------------------------------------------------------------------------------

output "human_review_queue_url" {
  description = "Human review SQS queue URL"
  value       = var.human_review.enabled ? module.human_review[0].review_queue_url : null
}

output "human_review_flow_definition_arn" {
  description = "A2I flow definition ARN"
  value       = var.human_review.enabled ? module.human_review[0].flow_definition_arn : null
}

#------------------------------------------------------------------------------
# API Module Outputs
#------------------------------------------------------------------------------

output "api_id" {
  description = "API Gateway REST API ID"
  value       = module.idp_api.api_id
}

output "api_invoke_url" {
  description = "API Gateway invoke URL"
  value       = module.idp_api.invoke_url
}

output "api_endpoints" {
  description = "API endpoint URLs"
  value       = module.idp_api.endpoints
}

output "api_lambda_arns" {
  description = "API Lambda function ARNs"
  value       = module.idp_api.lambda_arns
}

#------------------------------------------------------------------------------
# Authentication Module Outputs
#------------------------------------------------------------------------------

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = var.auth.enabled ? module.auth[0].user_pool_id : null
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = var.auth.enabled ? module.auth[0].user_pool_arn : null
}

output "cognito_user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = var.auth.enabled ? module.auth[0].user_pool_endpoint : null
}

output "cognito_client_ids" {
  description = "Cognito User Pool client IDs"
  value       = var.auth.enabled ? module.auth[0].client_ids : null
}

#------------------------------------------------------------------------------
# Deployment Summary
#------------------------------------------------------------------------------

output "deployment_summary" {
  description = "Deployment summary"
  value = {
    # Identity
    solution_name    = var.solution.name
    solution_abbr    = var.solution.abbr
    environment      = var.env
    environment_name = lookup({ prod = "Production", test = "Test", dr = "Disaster Recovery" }, var.env, var.env)
    name_prefix      = local.name_prefix
    region           = var.aws.region

    # Ownership
    cost_center  = var.ownership.cost_center
    owner        = var.ownership.owner_email
    project_code = var.ownership.project_code

    # Resources
    api_invoke_url       = module.idp_api.invoke_url
    documents_bucket     = module.storage.documents_bucket_name
    results_table        = module.storage.results_table_name
    state_machine        = module.document_processing.state_machine_name
    cognito_user_pool_id = var.auth.enabled ? module.auth[0].user_pool_id : null

    # Modules deployed
    deployed_modules = concat(
      ["storage", "document-processing", "idp-api"],
      var.human_review.enabled ? ["human-review"] : [],
      var.auth.enabled ? ["auth"] : []
    )

    # Architecture
    architecture = "serverless"
    services = [
      "S3",
      "DynamoDB",
      "Lambda",
      "Step Functions",
      "API Gateway",
      "Textract",
      "Comprehend",
      var.auth.enabled ? "Cognito" : null,
      var.human_review.enabled ? "A2I" : null
    ]
  }
}
