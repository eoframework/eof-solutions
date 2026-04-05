#------------------------------------------------------------------------------
# Secrets Setup - PROD Environment
#------------------------------------------------------------------------------
# Pre-provisions secrets before deploying main infrastructure.
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
  description = "AWS region"
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
      Project     = "prod-smp"
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

  name_prefix = "prod-smp"

  # Feature flags - Production settings
  create_kms_key        = true
  create_db_secret      = true
  create_cache_secret   = true
  create_api_key_secret = false

  # Secret configuration
  secret_recovery_window = 7  # 7 days for production

  tags = {
    Environment = "prod"
    Solution    = "sample-solution"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN"
  value       = module.secrets.kms_key_arn
}

output "db_password_secret_name" {
  description = "Database password secret name"
  value       = module.secrets.db_password_secret_name
}

output "cache_auth_token_param_name" {
  description = "Cache auth token parameter name"
  value       = module.secrets.cache_auth_token_param_name
}

output "secrets_summary" {
  description = "Summary of created secrets"
  value       = module.secrets.secrets_summary
}
