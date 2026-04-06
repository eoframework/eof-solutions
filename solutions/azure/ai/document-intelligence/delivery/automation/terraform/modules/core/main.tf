#------------------------------------------------------------------------------
# Core Infrastructure Module
# Creates: Resource Group, VNet, Subnets, Key Vault
# Uses: modules/azure/vnet, modules/azure/key-vault
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Resource Group (kept as direct resource - foundation for all)
#------------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = var.common_tags

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------------------------
# Virtual Network (via Azure module)
#------------------------------------------------------------------------------
module "vnet" {
  source = "../../azure/vnet"

  name                = "${var.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  address_space       = [var.network.vnet_cidr]

  subnets = {
    "${var.name_prefix}-functions-subnet" = {
      address_prefixes  = [var.network.subnet_functions]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.CognitiveServices"]
      delegation = {
        name                    = "functions-delegation"
        service_delegation_name = "Microsoft.Web/serverFarms"
        actions                 = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    "${var.name_prefix}-pe-subnet" = {
      address_prefixes                  = [var.network.subnet_private_endpoints]
      private_endpoint_network_policies = "Enabled"
    }
  }

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Key Vault (via Azure module)
#------------------------------------------------------------------------------
module "key_vault" {
  source = "../../azure/key-vault"

  name                      = "${replace(var.name_prefix, "-", "")}kv"
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  tenant_id                 = var.tenant_id
  enable_rbac_authorization = true
  purge_protection_enabled  = true
  soft_delete_retention_days = 90

  enable_network_acls    = var.network.enable_private_endpoints
  network_default_action = var.network.enable_private_endpoints ? "Deny" : "Allow"
  network_bypass         = "AzureServices"

  # Grant deployer access
  role_assignments = {
    deployer = {
      role_definition_name = "Key Vault Administrator"
      principal_id         = var.object_id
    }
  }

  common_tags = var.common_tags

  depends_on = [azurerm_resource_group.main]
}
