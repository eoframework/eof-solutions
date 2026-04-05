#------------------------------------------------------------------------------
# IDP API Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# API Gateway
#------------------------------------------------------------------------------

output "api_id" {
  description = "API Gateway REST API ID"
  value       = module.api_gateway.api_id
}

output "api_arn" {
  description = "API Gateway REST API ARN"
  value       = module.api_gateway.api_arn
}

output "invoke_url" {
  description = "API Gateway invoke URL"
  value       = module.api_gateway.invoke_url
}

output "execution_arn" {
  description = "API Gateway execution ARN"
  value       = module.api_gateway.execution_arn
}

output "stage_name" {
  description = "API Gateway stage name"
  value       = module.api_gateway.stage_name
}

#------------------------------------------------------------------------------
# API Endpoints
#------------------------------------------------------------------------------

output "endpoints" {
  description = "Map of API endpoints"
  value = {
    upload   = "${module.api_gateway.invoke_url}/documents"
    list     = "${module.api_gateway.invoke_url}/documents"
    get      = "${module.api_gateway.invoke_url}/documents/{documentId}"
    delete   = "${module.api_gateway.invoke_url}/documents/{documentId}"
    status   = "${module.api_gateway.invoke_url}/documents/{documentId}/status"
    results  = "${module.api_gateway.invoke_url}/documents/{documentId}/results"
    health   = "${module.api_gateway.invoke_url}/health"
  }
}

#------------------------------------------------------------------------------
# Lambda Functions
#------------------------------------------------------------------------------

output "lambda_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    upload  = module.lambda_upload.function_arn
    status  = module.lambda_status.function_arn
    results = module.lambda_results.function_arn
    list    = module.lambda_list.function_arn
    delete  = module.lambda_delete.function_arn
    health  = module.lambda_health.function_arn
  }
}

output "lambda_invoke_arns" {
  description = "Map of Lambda function invoke ARNs"
  value = {
    upload  = module.lambda_upload.invoke_arn
    status  = module.lambda_status.invoke_arn
    results = module.lambda_results.invoke_arn
    list    = module.lambda_list.invoke_arn
    delete  = module.lambda_delete.invoke_arn
    health  = module.lambda_health.invoke_arn
  }
}
