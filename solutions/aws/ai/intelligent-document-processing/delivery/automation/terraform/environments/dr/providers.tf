#------------------------------------------------------------------------------
# IDP Disaster Recovery Environment - Terraform & Provider Configuration
#------------------------------------------------------------------------------
# Prerequisites:
#   - Terraform >= 1.10.0 installed
#   - AWS CLI installed and configured
#   - S3 bucket and DynamoDB table for remote state (see setup/ directory)
#   - AWS credentials: profile, environment variables, or IAM role
#
# Note: DR state bucket is created in the DR region (us-west-2) for resilience
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0"

  #----------------------------------------------------------------------------
  # Remote State - S3 Backend
  #
  # Run the bootstrap script to create the S3 bucket and DynamoDB lock table:
  #   python ../setup/setup-backend.py dr
  #
  # This generates backend.tfvars. Initialise with:
  #   terraform init -backend-config=backend.tfvars
  #
  # Naming convention:
  #   S3 bucket:       {org}-idp-dr-terraform-state
  #   DynamoDB table:  {org}-idp-dr-terraform-locks
  #----------------------------------------------------------------------------
  backend "s3" {
    # All values supplied via -backend-config=backend.tfvars at init time
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Allows 6.x patches, blocks accidental 7.0 upgrade
    }
  }
}

#------------------------------------------------------------------------------
# Primary AWS Provider - DR region (us-west-2)
#
# Authentication (in precedence order):
#   1. Environment variables: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
#   2. Named profile:         aws.profile in project.tfvars → ~/.aws/credentials
#   3. IAM instance/task/web identity role (CI/CD and AWS compute)
#------------------------------------------------------------------------------
provider "aws" {
  region  = var.aws.region
  profile = try(var.aws.profile, null) != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}

#------------------------------------------------------------------------------
# Secondary AWS Provider - Points back to production region (us-east-1)
# Used for reading prod state or cross-region operations initiated from DR
#------------------------------------------------------------------------------
provider "aws" {
  alias   = "dr"
  region  = try(var.aws.dr_region, "us-east-1")
  profile = try(var.aws.profile, null) != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}
