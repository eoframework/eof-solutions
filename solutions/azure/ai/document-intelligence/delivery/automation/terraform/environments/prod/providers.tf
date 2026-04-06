#------------------------------------------------------------------------------
# Azure Document Intelligence - Production Environment
# Provider Configuration
#
# Credentials are loaded from credentials.auto.tfvars (git-ignored).
# Generate via: setup/scripts/Initialize-TerraformConfig.ps1
# Version constraints and backend are defined in versions.tf.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Primary provider — Azure Resource Manager
#------------------------------------------------------------------------------
provider "azurerm" {
  environment     = var.azure_environment
  subscription_id = var.arm_subscription_id
  tenant_id       = var.arm_tenant_id
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret

  # Prevents Terraform from auto-registering all resource providers on every
  # run — requires elevated subscription permissions and slows plan/apply.
  resource_provider_registrations = "none"

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}

#------------------------------------------------------------------------------
# Entra ID (Azure AD) provider
#------------------------------------------------------------------------------
provider "azuread" {
  environment   = var.azure_environment
  tenant_id     = var.arm_tenant_id
  client_id     = var.arm_client_id
  client_secret = var.arm_client_secret
}

#------------------------------------------------------------------------------
# DR region provider alias (used when dr.enabled = true)
#------------------------------------------------------------------------------
provider "azurerm" {
  alias           = "dr"
  environment     = var.azure_environment
  subscription_id = var.arm_subscription_id
  tenant_id       = var.arm_tenant_id
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret

  resource_provider_registrations = "none"

  features {}
}
