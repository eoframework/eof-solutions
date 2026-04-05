#------------------------------------------------------------------------------
# Secrets Setup - DR Environment
#------------------------------------------------------------------------------
# Pre-provisions IDP secrets in the DR region before deploying main
# infrastructure. Run once before the first `terraform apply` in
# environments/dr.
#
# DR secrets are independent of prod — they use different names and are
# deployed in the DR region (us-west-2 by default). This ensures the DR
# environment is self-contained and can operate without the prod region.
#
# Usage:
#   cd setup/secrets/dr
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
  description = "AWS DR region (must match environments/dr aws.region)"
  type        = string
  default     = "us-west-2"
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
      Project     = "idp-dr"
      Environment = "dr"
      ManagedBy   = "Terraform"
      Purpose     = "Secrets"
      Standby     = "true"
    }
  }
}

#------------------------------------------------------------------------------
# Secrets Module
#------------------------------------------------------------------------------

module "secrets" {
  source = "../modules/secrets"

  name_prefix = "idp-dr"

  # DR: dedicated KMS key (matches prod security posture), API key, workteam
  create_kms_key         = true
  create_api_key_secret  = true
  create_workteam_secret = true  # Required when human_review.use_private_workforce = true

  secret_recovery_window = 7  # 7-day safety window for DR (matches prod)

  tags = {
    Environment = "dr"
    Solution    = "intelligent-document-processing"
    Purpose     = "DisasterRecovery"
    Standby     = "true"
  }
}

#------------------------------------------------------------------------------
# Outputs
#------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "KMS key ARN for secrets encryption in DR region"
  value       = module.secrets.kms_key_arn
}

output "api_key_secret_name" {
  description = "Secrets Manager secret name for IDP API key (DR region)"
  value       = module.secrets.api_key_secret_name
}

output "workteam_secret_name" {
  description = "Secrets Manager secret name for A2I workteam credentials (DR region)"
  value       = module.secrets.workteam_secret_name
}

output "secrets_summary" {
  description = "Summary of created secrets"
  value       = module.secrets.secrets_summary
}
