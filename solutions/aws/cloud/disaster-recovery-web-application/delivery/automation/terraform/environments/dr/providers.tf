#------------------------------------------------------------------------------
# DR Web Application - DR Environment Providers
#------------------------------------------------------------------------------
# Secondary region deployment for failover

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
  profile = var.aws.profile != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}

# Primary region provider for cross-region access
provider "aws" {
  alias   = "primary"
  region  = var.aws.dr_region  # us-east-1 (primary)
  profile = var.aws.profile != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}

# DR alias required by best-practices module (points to primary from DR perspective)
provider "aws" {
  alias   = "dr"
  region  = var.aws.dr_region
  profile = var.aws.profile != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}
