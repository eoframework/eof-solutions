#------------------------------------------------------------------------------
# IDP Security Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# KMS Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.main.arn
}

output "kms_key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.main.key_id
}

output "kms_alias_arn" {
  description = "KMS alias ARN"
  value       = aws_kms_alias.main.arn
}

#------------------------------------------------------------------------------
# Security Group Outputs
#------------------------------------------------------------------------------

output "security_group_ids" {
  description = "Map of security group IDs keyed by security_groups key"
  value       = { for key, sg in aws_security_group.this : key => sg.id }
}

output "security_group_id" {
  description = "Security group ID lookup by key (use: module.security.security_group_id[\"idp-lambda\"])"
  value       = { for key, sg in aws_security_group.this : key => sg.id }
}

#------------------------------------------------------------------------------
# Computed Lambda VPC Configuration
#------------------------------------------------------------------------------
# Convenience output consumed by downstream modules (document-processing, api, etc.)
# Passes subnet IDs and Lambda SG ID as a single object.
#------------------------------------------------------------------------------

output "lambda_vpc" {
  description = "Computed Lambda VPC config for passing to Lambda modules"
  value = var.lambda_vpc_enabled ? {
    subnet_ids         = null  # populated by environment main.tf from networking module
    security_group_ids = contains(keys(aws_security_group.this), "idp-lambda") ? [
      aws_security_group.this["idp-lambda"].id
    ] : []
  } : {
    subnet_ids         = null
    security_group_ids = []
  }
}

output "lambda_security_group_id" {
  description = "Lambda security group ID (null if VPC mode disabled or SG not defined)"
  value = (var.lambda_vpc_enabled && contains(keys(aws_security_group.this), "idp-lambda")) ? (
    aws_security_group.this["idp-lambda"].id
  ) : null
}
