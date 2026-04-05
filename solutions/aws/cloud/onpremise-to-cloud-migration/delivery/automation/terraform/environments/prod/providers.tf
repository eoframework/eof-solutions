#------------------------------------------------------------------------------
# Cloud Migration - Production Environment Providers
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws.region
  profile = var.aws.profile != "" ? var.aws.profile : null

  default_tags {
    tags = local.common_tags
  }
}
