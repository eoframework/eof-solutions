#------------------------------------------------------------------------------
# Processing Module
# Creates: Document Intelligence, Function App, Logic App, Service Plan
# Uses: modules/azure/document-intelligence, modules/azure/function-app, modules/azure/logic-app
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Azure Document Intelligence (via Azure module)
#------------------------------------------------------------------------------
module "document_intelligence" {
  source = "../../azure/document-intelligence"

  name                  = "${var.name_prefix}-docintel"
  resource_group_name   = var.resource_group_name
  location              = var.location
  sku_name              = var.docintel.sku
  custom_subdomain_name = "${var.name_prefix}-docintel"
  identity_type         = "SystemAssigned"

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Application Insights (for Function App)
#------------------------------------------------------------------------------
resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Function App (via Azure module)
#------------------------------------------------------------------------------
module "function_app" {
  source = "../../azure/function-app"

  name                       = "${var.name_prefix}-func"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  storage_account_name       = var.storage_account_name
  storage_account_access_key = var.storage_connection_string

  # Service Plan
  service_plan_name = "${var.name_prefix}-asp"
  sku_name          = var.function_config.sku

  # Identity
  identity_type = "UserAssigned"
  identity_ids  = [var.managed_identity_id]

  # Application Stack
  application_stack = {
    python_version = var.function_config.runtime_version
  }
  worker_runtime = var.function_config.runtime

  # Application Insights
  application_insights_connection_string = azurerm_application_insights.main.connection_string
  application_insights_key               = azurerm_application_insights.main.instrumentation_key

  # VNet Integration
  vnet_integration_subnet_id = var.subnet_id

  # CORS
  cors_allowed_origins = ["https://portal.azure.com"]

  # App Settings
  app_settings = {
    # Application Settings
    "ENVIRONMENT"          = var.application.environment
    "LOG_LEVEL"            = var.application.log_level
    "CONFIDENCE_THRESHOLD" = var.application.confidence_threshold

    # Document Intelligence
    "DOC_INTEL_ENDPOINT"      = module.document_intelligence.endpoint
    "DOC_INTEL_MODEL_INVOICE" = var.docintel.model_invoice
    "DOC_INTEL_MODEL_RECEIPT" = var.docintel.model_receipt
    "DOC_INTEL_MODEL_CUSTOM"  = var.docintel.model_custom

    # Storage
    "STORAGE_ACCOUNT_NAME" = var.storage_account_name

    # Cosmos DB
    "COSMOS_ENDPOINT" = var.cosmos_endpoint

    # Key Vault
    "KEY_VAULT_URI" = var.key_vault_uri

    # Function Runtime
    "PYTHON_ENABLE_WORKER_EXTENSIONS" = "1"
  }

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Logic App (via Azure module)
#------------------------------------------------------------------------------
module "logic_app" {
  source = "../../azure/logic-app"

  name                = "${var.name_prefix}-logic"
  resource_group_name = var.resource_group_name
  location            = var.location
  identity_type       = "SystemAssigned"

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Store Document Intelligence Key in Key Vault
#------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "doc_intel_key" {
  name         = "doc-intel-key"
  value        = module.document_intelligence.primary_access_key
  key_vault_id = data.azurerm_key_vault.main.id
}

data "azurerm_key_vault" "main" {
  name                = split("/", var.key_vault_uri)[2]
  resource_group_name = var.resource_group_name
}
