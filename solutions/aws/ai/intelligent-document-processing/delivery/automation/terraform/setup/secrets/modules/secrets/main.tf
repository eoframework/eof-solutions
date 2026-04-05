#------------------------------------------------------------------------------
# Secrets Module - IDP (Intelligent Document Processing)
#------------------------------------------------------------------------------
# Pre-provisions secrets before deploying main IDP infrastructure.
# Referenced by environment-specific configurations (prod, test, dr).
#
# Secrets created:
#   - KMS key for secrets encryption (optional - use AWS managed key in test)
#   - API key secret for external service integrations
#   - Workteam credentials for SageMaker A2I human review (optional)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#------------------------------------------------------------------------------
# KMS Key for Secrets Encryption
# Optional - skipped in test to reduce cost; AWS managed key used instead
#------------------------------------------------------------------------------

resource "aws_kms_key" "secrets" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for ${var.name_prefix} secrets encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, { Name = "${var.name_prefix}-secrets-key" })
}

resource "aws_kms_alias" "secrets" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets[0].key_id
}

#------------------------------------------------------------------------------
# API Key - Secrets Manager
# Used by external systems calling the IDP REST API
#------------------------------------------------------------------------------

resource "random_password" "api_key" {
  count   = var.create_api_key_secret ? 1 : 0
  length  = 48
  special = false  # URL-safe: no special chars for use in Authorization headers
}

resource "aws_secretsmanager_secret" "api_key" {
  count                   = var.create_api_key_secret ? 1 : 0
  name                    = "${var.name_prefix}-${var.api_key_secret_suffix}"
  description             = "API key for external integrations with IDP (${var.name_prefix})"
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].arn : null
  recovery_window_in_days = var.secret_recovery_window

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-api-key"
    Component = "API"
  })
}

resource "aws_secretsmanager_secret_version" "api_key" {
  count         = var.create_api_key_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.api_key[0].id
  secret_string = random_password.api_key[0].result
}

#------------------------------------------------------------------------------
# Workteam Credentials - Secrets Manager
# Optional: stores SageMaker A2I private workforce credentials
# Only needed when human_review.use_private_workforce = true
#------------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "workteam" {
  count                   = var.create_workteam_secret ? 1 : 0
  name                    = "${var.name_prefix}-${var.workteam_secret_suffix}"
  description             = "SageMaker A2I workteam credentials for IDP human review (${var.name_prefix})"
  kms_key_id              = var.create_kms_key ? aws_kms_key.secrets[0].arn : null
  recovery_window_in_days = var.secret_recovery_window

  tags = merge(var.tags, {
    Name      = "${var.name_prefix}-workteam-credentials"
    Component = "HumanReview"
  })
}

resource "aws_secretsmanager_secret_version" "workteam" {
  count     = var.create_workteam_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.workteam[0].id
  # Placeholder — operator must update with actual workteam ARN and credentials
  secret_string = jsonencode({
    workteam_arn = "REPLACE_WITH_WORKTEAM_ARN"
    note         = "Update this secret with actual workteam credentials before enabling human review"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
