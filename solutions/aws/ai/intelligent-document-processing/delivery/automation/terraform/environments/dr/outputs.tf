#------------------------------------------------------------------------------
# IDP Disaster Recovery Environment Outputs
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
# DR Status & Failover Information
#------------------------------------------------------------------------------

output "dr_status" {
  description = "DR environment status summary"
  value = {
    environment       = var.env
    region            = var.aws.region
    production_region = var.aws.dr_region
    status            = "STANDBY"
    purpose           = "DisasterRecovery"

    # Resources ready for failover
    documents_bucket  = module.storage.documents_bucket_name
    results_table     = module.storage.results_table_name
    jobs_table        = module.storage.jobs_table_name
    api_endpoint      = module.idp_api.invoke_url
    state_machine_arn = module.document_processing.state_machine_arn

    # Auth status
    cognito_enabled = var.auth.enabled
    user_pool_id    = var.auth.enabled ? module.auth[0].user_pool_id : null
  }
}

output "failover_runbook" {
  description = "Step-by-step failover procedure"
  value = {
    pre_failover = [
      "1. Verify S3 documents are replicated: aws s3 ls s3://${module.storage.documents_bucket_name}",
      "2. Check latest DynamoDB backup in AWS Backup console",
      "3. Verify Lambda functions are deployed: terraform plan (should show no changes)",
      "4. Test API health endpoint: curl ${module.idp_api.invoke_url}/health"
    ]

    failover_steps = [
      "1. Restore DynamoDB tables from backup:",
      "   - Go to AWS Backup console in ${var.aws.region}",
      "   - Select latest backup for ${module.storage.results_table_name}",
      "   - Click 'Restore' and use same table name",
      "   - Repeat for ${module.storage.jobs_table_name}",
      "2. Wait for table restoration (usually 5-15 minutes)",
      "3. Update DNS to point to DR API endpoint:",
      "   - API Endpoint: ${module.idp_api.invoke_url}",
      "4. If using Cognito, inform users to re-register or import users",
      "5. Test document upload and processing workflow"
    ]

    post_failover = [
      "1. Monitor CloudWatch logs for errors",
      "2. Verify document processing is working",
      "3. Check Step Functions executions",
      "4. Notify stakeholders of successful failover"
    ]

    failback = [
      "1. Once production is restored, sync data back to production",
      "2. Update DNS to point back to production",
      "3. Verify production is functioning correctly"
    ]
  }
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

    # DR-specific
    purpose           = "DisasterRecovery"
    status            = "STANDBY"
    production_region = var.aws.dr_region

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
