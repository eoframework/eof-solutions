#------------------------------------------------------------------------------
# Azure Document Intelligence - Test Environment
# Terraform Version and Provider Requirements
#------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.10.0"

  backend "azurerm" {
    # Configuration loaded at init time via:
    #   terraform init -backend-config="backend.tfvars"
    # See setup/backend/state-backend.sh to provision the backend storage
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}
