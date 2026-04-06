#------------------------------------------------------------------------------
# Azure Document Intelligence - DR Environment
#------------------------------------------------------------------------------
# Warm standby deployment in secondary region:
# - Full solution stack deployed in dr_region
# - Replication from primary handled by prod environment's dr module
# - module.dr disabled here (this environment IS the DR target)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  environment = var.env
  name_prefix = "${var.solution.abbr}-${local.environment}"

  project = {
    name        = var.solution.abbr
    environment = local.environment
  }

  common_tags = {
    Solution     = var.solution.name
    SolutionAbbr = var.solution.abbr
    Environment  = local.environment
    Provider     = var.solution.provider_name
    Category     = var.solution.category_name
    Region       = var.azure.region
    ManagedBy    = "terraform"
    CostCenter   = var.ownership.cost_center
    Owner        = var.ownership.owner_email
    ProjectCode  = var.ownership.project_code
    Purpose      = "DisasterRecovery"
  }

  function_config = {
    name_prefix     = local.name_prefix
    runtime         = "python"
    runtime_version = "3.11"
    sku             = var.compute.function_plan_sku
    min_instances   = var.compute.autoscale_min_instances
    max_instances   = var.compute.autoscale_max_instances
  }
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

#===============================================================================
# FOUNDATION
#===============================================================================
#------------------------------------------------------------------------------
# Core Infrastructure (Resource Group, VNet, Key Vault)
#------------------------------------------------------------------------------
module "core" {
  source = "../../modules/core"

  name_prefix = local.name_prefix
  location    = var.azure.region
  common_tags = local.common_tags
  network     = var.network
  tenant_id   = var.arm_tenant_id
  object_id   = data.azurerm_client_config.current.object_id
}

#------------------------------------------------------------------------------
# Security (Managed Identity, RBAC, Encryption Key)
#------------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  name_prefix         = local.name_prefix
  location            = var.azure.region
  resource_group_name = module.core.resource_group_name
  common_tags         = local.common_tags
  key_vault_id        = module.core.key_vault_id
  security            = var.security

  depends_on = [module.core]
}

#===============================================================================
# CORE SOLUTION
#===============================================================================
#------------------------------------------------------------------------------
# Storage (Blob Storage, Cosmos DB)
#------------------------------------------------------------------------------
module "storage" {
  source = "../../modules/storage"

  name_prefix         = local.name_prefix
  location            = var.azure.region
  resource_group_name = module.core.resource_group_name
  common_tags         = local.common_tags
  subnet_id           = var.network.enable_private_endpoints ? module.core.private_endpoint_subnet_id : null
  key_vault_id        = module.core.key_vault_id
  storage             = var.storage
  database            = var.database

  depends_on = [module.security]
}

#------------------------------------------------------------------------------
# Processing (Document Intelligence, Functions, Logic Apps)
#------------------------------------------------------------------------------
module "processing" {
  source = "../../modules/processing"

  name_prefix               = local.name_prefix
  location                  = var.azure.region
  resource_group_name       = module.core.resource_group_name
  common_tags               = local.common_tags
  function_config           = local.function_config
  subnet_id                 = var.network.enable_private_endpoints ? module.core.functions_subnet_id : null
  storage_account_name      = module.storage.storage_account_name
  storage_connection_string = module.storage.storage_connection_string
  cosmos_endpoint           = module.storage.cosmos_endpoint
  cosmos_key                = module.storage.cosmos_key
  key_vault_uri             = module.core.key_vault_uri
  managed_identity_id       = module.security.managed_identity_id
  application               = var.application
  docintel                  = var.docintel

  depends_on = [module.storage]
}

#===============================================================================
# OPERATIONS
#===============================================================================
#------------------------------------------------------------------------------
# Monitoring
#------------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix         = local.name_prefix
  location            = var.azure.region
  resource_group_name = module.core.resource_group_name
  common_tags         = local.common_tags
  function_app_id     = module.processing.function_app_id
  cosmos_account_name = module.storage.cosmos_account_name
  storage_account_id  = module.storage.storage_account_id
  monitoring          = var.monitoring

  depends_on = [module.processing]
}

#------------------------------------------------------------------------------
# Best Practices (Backup, Budget, Policies)
#------------------------------------------------------------------------------
module "best_practices" {
  source = "../../modules/best-practices"

  name_prefix         = local.name_prefix
  location            = var.azure.region
  resource_group_name = module.core.resource_group_name
  common_tags         = local.common_tags
  action_group_id     = module.monitoring.action_group_id
  backup              = var.backup
  budget              = var.budget
  policy              = var.policy

  depends_on = [module.monitoring]
}

#===============================================================================
# INTEGRATIONS
#===============================================================================
module "integrations" {
  source = "../../modules/integrations"

  name_prefix         = local.name_prefix
  resource_group_name = module.core.resource_group_name
  common_tags         = local.common_tags
  storage_account_id  = module.storage.storage_account_id
  input_container     = var.storage.input_container
  function_app_id     = module.processing.function_app_id
  cosmos_account_id   = module.storage.cosmos_account_id
  action_group_id     = module.monitoring.action_group_id
  enable_alerts       = var.monitoring.enable_alerts

  depends_on = [module.processing, module.monitoring]
}

#===============================================================================
# CHECK BLOCKS (plan-time validation)
#===============================================================================
check "budget_requires_notification_email" {
  assert {
    condition     = !var.budget.enabled || var.budget.notification_email != ""
    error_message = "budget.notification_email must be set when budget.enabled = true."
  }
}

check "dr_requires_distinct_regions" {
  assert {
    condition     = var.azure.region != var.azure.dr_region
    error_message = "azure.region and azure.dr_region must be different regions."
  }
}

check "backup_requires_positive_retention" {
  assert {
    condition     = !var.backup.enabled || var.backup.retention_days > 0
    error_message = "backup.retention_days must be greater than 0 when backup.enabled = true."
  }
}
