#------------------------------------------------------------------------------
# IDP Storage Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Documents S3 Bucket
#------------------------------------------------------------------------------

output "documents_bucket_name" {
  description = "Name of the documents S3 bucket"
  value       = module.documents_bucket.bucket_name
}

output "documents_bucket_id" {
  description = "ID (name) of the documents S3 bucket"
  value       = module.documents_bucket.bucket_name
}

output "documents_bucket_arn" {
  description = "ARN of the documents S3 bucket"
  value       = module.documents_bucket.bucket_arn
}

output "documents_bucket_domain_name" {
  description = "Domain name of the documents S3 bucket"
  value       = module.documents_bucket.bucket_domain_name
}

#------------------------------------------------------------------------------
# Output S3 Bucket (optional)
#------------------------------------------------------------------------------

output "output_bucket_name" {
  description = "Name of the output S3 bucket (if created)"
  value       = var.storage.create_output_bucket ? module.output_bucket[0].bucket_name : null
}

output "output_bucket_arn" {
  description = "ARN of the output S3 bucket (if created)"
  value       = var.storage.create_output_bucket ? module.output_bucket[0].bucket_arn : null
}

#------------------------------------------------------------------------------
# Results DynamoDB Table
#------------------------------------------------------------------------------

output "results_table_name" {
  description = "Name of the results DynamoDB table"
  value       = module.results_table.table_name
}

output "results_table_arn" {
  description = "ARN of the results DynamoDB table"
  value       = module.results_table.table_arn
}

output "results_table_stream_arn" {
  description = "Stream ARN of the results DynamoDB table (if enabled)"
  value       = module.results_table.stream_arn
}

#------------------------------------------------------------------------------
# Processing Jobs DynamoDB Table
#------------------------------------------------------------------------------

output "jobs_table_name" {
  description = "Name of the processing jobs DynamoDB table"
  value       = module.jobs_table.table_name
}

output "jobs_table_arn" {
  description = "ARN of the processing jobs DynamoDB table"
  value       = module.jobs_table.table_arn
}

#------------------------------------------------------------------------------
# Index ARNs for IAM policies
#------------------------------------------------------------------------------

output "results_table_index_arns" {
  description = "ARNs of all indexes on the results table"
  value = [
    "${module.results_table.table_arn}/index/userId-createdAt-index",
    "${module.results_table.table_arn}/index/status-createdAt-index",
    "${module.results_table.table_arn}/index/documentType-createdAt-index"
  ]
}

output "jobs_table_index_arns" {
  description = "ARNs of all indexes on the jobs table"
  value = [
    "${module.jobs_table.table_arn}/index/documentId-index",
    "${module.jobs_table.table_arn}/index/jobStatus-startedAt-index"
  ]
}

#------------------------------------------------------------------------------
# Consolidated Outputs Object (for lean main.tf pattern)
#------------------------------------------------------------------------------

output "outputs" {
  description = "Consolidated storage outputs for passing to other modules"
  value = {
    # Documents bucket
    documents_bucket_name        = module.documents_bucket.bucket_name
    documents_bucket_id          = module.documents_bucket.bucket_name
    documents_bucket_arn         = module.documents_bucket.bucket_arn
    documents_bucket_domain_name = module.documents_bucket.bucket_domain_name

    # Output bucket (optional)
    output_bucket_name = var.storage.create_output_bucket ? module.output_bucket[0].bucket_name : null
    output_bucket_arn  = var.storage.create_output_bucket ? module.output_bucket[0].bucket_arn : null

    # Results table
    results_table_name       = module.results_table.table_name
    results_table_arn        = module.results_table.table_arn
    results_table_stream_arn = module.results_table.stream_arn

    # Jobs table
    jobs_table_name = module.jobs_table.table_name
    jobs_table_arn  = module.jobs_table.table_arn
  }
}
