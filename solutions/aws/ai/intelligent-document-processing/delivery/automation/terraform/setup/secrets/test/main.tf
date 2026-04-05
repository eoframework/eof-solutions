#------------------------------------------------------------------------------
# Secrets Setup - TEST Environment
#------------------------------------------------------------------------------
# Pre-provisions IDP secrets before deploying main infrastructure.
# Run once before the first `terraform apply` in environments/test.
#
# Usage:
#   cd setup/secrets/test
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
  description = "AWS region (must match environments/test)"
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
      Project     = "idp-test"
      Environment = "test"
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

  name_prefix = "idp-test"

  # Test: AWS managed key (cost-optimized), API key only, no workteam secret
  create_kms_key         = false  # Use AWS managed key in test to reduce cost
  create_api_key_secret  = true
  create_workteam_secret = false  # Human review disabled in test by default

  secret_recovery_window = 0  # Immediate deletion for test (faster teardown)

  tags = {
    Environment = "test"
    Solution    = "intelligent-document-processing"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption (null in test - uses AWS managed key)"
  value       = module.secrets.kms_key_arn
}

output "api_key_secret_name" {
  description = "Secrets Manager secret name for IDP API key"
  value       = module.secrets.api_key_secret_name
}

output "secrets_summary" {
  description = "Summary of created secrets"
  value       = module.secrets.secrets_summary
}
