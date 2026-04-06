# Provider Configuration for Backup Plans Module
# Requires DR provider alias for cross-region backup vault

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.dr]
    }
  }
}
