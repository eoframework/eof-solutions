#------------------------------------------------------------------------------
# DR Web Application Storage Module - Outputs
#------------------------------------------------------------------------------

output "bucket_id" {
  description = "ID of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the S3 bucket"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "replication_role_arn" {
  description = "ARN of the S3 replication IAM role"
  value       = var.storage.enable_replication ? aws_iam_role.replication[0].arn : null
}
