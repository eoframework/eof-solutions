#------------------------------------------------------------------------------
# Secrets Setup - PROD Environment
#------------------------------------------------------------------------------
# Pre-provisions IDP secrets before deploying main infrastructure.
# Run once before the first `terraform apply` in environments/prod.
#
# Usage:
#   cd setup/secrets/prod
#   terraform init
#   terraform apply
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

#------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region (must match environments/prod)"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name (optional)"
  type        = string
  default     = ""
}

#------------------------------------------------------------------------------
# Provider Configuration
#------------------------------------------------------------------------------

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  default_tags {
    tags = {
      Project     = "idp-prod"
      Environment = "prod"
      ManagedBy   = "Terraform"
      Purpose     = "Secrets"
    }
  }
}

#------------------------------------------------------------------------------
# Secrets Module
#------------------------------------------------------------------------------

module "secrets" {
  source = "../modules/secrets"

  name_prefix = "idp-prod"

  # Production: dedicated KMS key, API key, workteam credentials
  create_kms_key         = true
  create_api_key_secret  = true
  create_workteam_secret = true  # Required when human_review.use_private_workforce = true

  secret_recovery_window = 7  # 7-day safety window for production

  tags = {
    Environment = "prod"
    Solution    = "intelligent-document-processing"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption"
  value       = module.secrets.kms_key_arn
}

output "api_key_secret_name" {
  description = "Secrets Manager secret name for IDP API key"
  value       = module.secrets.api_key_secret_name
}

output "workteam_secret_name" {
  description = "Secrets Manager secret name for A2I workteam credentials"
  value       = module.secrets.workteam_secret_name
}

output "secrets_summary" {
  description = "Summary of created secrets"
  value       = module.secrets.secrets_summary
}
