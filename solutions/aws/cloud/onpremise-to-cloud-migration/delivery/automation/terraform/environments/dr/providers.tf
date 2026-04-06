#------------------------------------------------------------------------------
# Cloud Migration - DR Environment Providers
#------------------------------------------------------------------------------
# Secondary region standby deployment

terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    # Values loaded from backend.tfvars via -backend-config flag
    # Run setup/backend/state-backend.sh to create backend resources
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# DR region as primary for this environment
provider "aws" {
  region  = var.aws.region  # us-west-2 for DR
  profile = try(var.aws.profile, null) != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}

# DR region provider (used by best-practices cross-region backup)
provider "aws" {
  alias   = "dr"
  region  = var.aws.dr_region
  profile = var.aws.profile != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}
