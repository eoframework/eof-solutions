# Provider Configuration for Best Practices Module
# Requires DR provider alias for cross-region backup (passed to backup-plans)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      configuration_aliases = [aws.dr]
    }
  }
}
