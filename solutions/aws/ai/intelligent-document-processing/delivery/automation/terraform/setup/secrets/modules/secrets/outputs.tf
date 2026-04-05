#------------------------------------------------------------------------------
# Secrets Module - Outputs
#------------------------------------------------------------------------------
# Note: Actual secret VALUES are never exposed in outputs.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# KMS Key
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption (null if using AWS managed key)"
  value       = var.create_kms_key ? aws_kms_key.secrets[0].arn : null
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = var.create_kms_key ? aws_kms_alias.secrets[0].name : null
}

#------------------------------------------------------------------------------
# API Key Secret
#------------------------------------------------------------------------------

output "api_key_secret_name" {
  description = "Secrets Manager secret name for the IDP API key"
  value       = var.create_api_key_secret ? aws_secretsmanager_secret.api_key[0].name : null
}

output "api_key_secret_arn" {
  description = "Secrets Manager secret ARN for the IDP API key"
  value       = var.create_api_key_secret ? aws_secretsmanager_secret.api_key[0].arn : null
}

#------------------------------------------------------------------------------
# Workteam Credentials Secret
#------------------------------------------------------------------------------

output "workteam_secret_name" {
  description = "Secrets Manager secret name for A2I workteam credentials"
  value       = var.create_workteam_secret ? aws_secretsmanager_secret.workteam[0].name : null
}

output "workteam_secret_arn" {
  description = "Secrets Manager secret ARN for A2I workteam credentials"
  value       = var.create_workteam_secret ? aws_secretsmanager_secret.workteam[0].arn : null
}

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------

output "secrets_summary" {
  description = "Summary of created secrets for operational reference"
  value = {
    api_key = var.create_api_key_secret ? {
      type   = "SecretsManager"
      name   = aws_secretsmanager_secret.api_key[0].name
      lookup = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.api_key[0].name}"
    } : null

    workteam = var.create_workteam_secret ? {
      type   = "SecretsManager"
      name   = aws_secretsmanager_secret.workteam[0].name
      lookup = "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.workteam[0].name}"
    } : null
  }
}
