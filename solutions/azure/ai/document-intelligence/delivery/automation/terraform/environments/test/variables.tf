#------------------------------------------------------------------------------
# Azure Document Intelligence - Test Environment Variables
# All configuration is defined as grouped objects for clean module calls.
# Values are set in config/*.tfvars. Credentials are in credentials.auto.tfvars.
#------------------------------------------------------------------------------

#==============================================================================
# CREDENTIALS (credentials.auto.tfvars — git-ignored, never commit)
# Generate via: setup/scripts/Initialize-TerraformConfig.ps1
#==============================================================================
variable "arm_subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "arm_tenant_id" {
  description = "Entra ID (Azure AD) tenant ID"
  type        = string
  sensitive   = true
}

variable "arm_client_id" {
  description = "Service principal application (client) ID"
  type        = string
  sensitive   = true
}

variable "arm_client_secret" {
  description = "Service principal client secret"
  type        = string
  sensitive   = true
}

#==============================================================================
# CONFIGURATION (config/*.tfvars)
#==============================================================================

#------------------------------------------------------------------------------
# Top-level identifiers (project.tfvars)
#------------------------------------------------------------------------------
variable "project_name" {
  description = "Short project identifier used in all resource names (e.g. docintel-prod-*)."
  type        = string
  validation {
    condition     = can(regex("^[0-9A-Za-z]{3,16}$", var.project_name))
    error_message = "project_name must be 3-16 alphanumeric characters with no spaces or hyphens."
  }
}

variable "env" {
  description = "Environment identifier — set explicitly, not inferred from directory path."
  type        = string
  validation {
    condition     = contains(["dev", "test", "stage", "dr", "prod"], var.env)
    error_message = "env must be one of: dev, test, stage, dr, prod."
  }
}

variable "azure_environment" {
  description = "Azure cloud environment. Use 'public' for commercial, 'usgovernment' for sovereign."
  type        = string
  default     = "public"
  validation {
    condition     = contains(["public", "usgovernment", "usgovernmentl4", "usgovernmentl5", "china"], var.azure_environment)
    error_message = "azure_environment must be one of: public, usgovernment, usgovernmentl4, usgovernmentl5, china."
  }
}

#------------------------------------------------------------------------------
# Azure region configuration (project.tfvars)
#------------------------------------------------------------------------------
variable "azure" {
  description = "Azure region configuration"
  type = object({
    region    = string # Primary deployment region
    dr_region = string # Secondary / failover region
  })
}

#------------------------------------------------------------------------------
# Solution metadata (project.tfvars)
#------------------------------------------------------------------------------
variable "solution" {
  description = "Solution identification and metadata"
  type = object({
    name          = string
    abbr          = string
    provider_name = string
    category_name = string
  })
}

variable "ownership" {
  description = "Solution ownership and cost allocation"
  type = object({
    cost_center  = string
    owner_email  = string
    project_code = string
  })
}

#------------------------------------------------------------------------------
# Network configuration (networking.tfvars)
#------------------------------------------------------------------------------
variable "network" {
  description = "Virtual network configuration"
  type = object({
    vnet_cidr                = string
    subnet_functions         = string
    subnet_private_endpoints = string
    enable_private_endpoints = bool
  })
}

#------------------------------------------------------------------------------
# Compute configuration (compute.tfvars)
#------------------------------------------------------------------------------
variable "compute" {
  description = "Azure Functions compute configuration"
  type = object({
    function_plan_type      = string
    function_plan_sku       = string
    autoscale_min_instances = number
    autoscale_max_instances = number
  })
}

#------------------------------------------------------------------------------
# Storage configuration (storage.tfvars)
#------------------------------------------------------------------------------
variable "storage" {
  description = "Blob storage configuration"
  type = object({
    account_tier         = string
    replication_type     = string
    input_container      = string
    processed_container  = string
    failed_container     = string
    archive_container    = string
    retention_hot_days   = number
    retention_cool_days  = number
    retention_total_days = number
  })
}

#------------------------------------------------------------------------------
# Database configuration (database.tfvars)
#------------------------------------------------------------------------------
variable "database" {
  description = "Cosmos DB configuration"
  type = object({
    cosmos_offer_type             = string
    cosmos_consistency_level      = string
    cosmos_database_name          = string
    cosmos_metadata_container     = string
    cosmos_results_container      = string
    cosmos_max_throughput         = number
    cosmos_enable_free_tier       = bool
    cosmos_backup_type            = string
    cosmos_backup_interval_hours  = number
    cosmos_backup_retention_hours = number
  })
}

#------------------------------------------------------------------------------
# Security configuration (security.tfvars)
#------------------------------------------------------------------------------
variable "security" {
  description = "Security and access control configuration"
  type = object({
    enable_customer_managed_key = bool
    admin_group_id              = string
    reviewer_group_id           = string
    user_group_id               = string
  })
}

#------------------------------------------------------------------------------
# Application configuration (application.tfvars)
#------------------------------------------------------------------------------
variable "application" {
  description = "Application runtime settings"
  type = object({
    environment          = string
    log_level            = string
    confidence_threshold = number
  })
}

variable "docintel" {
  description = "Azure Document Intelligence service configuration"
  type = object({
    sku                 = string
    model_invoice       = string
    model_receipt       = string
    model_custom        = optional(string, "")
    enable_custom_model = bool
  })
}

#------------------------------------------------------------------------------
# Monitoring configuration (monitoring.tfvars)
#------------------------------------------------------------------------------
variable "monitoring" {
  description = "Azure Monitor configuration"
  type = object({
    enable_alerts         = bool
    enable_dashboard      = bool
    log_retention_days    = number
    alert_email           = string
    health_check_interval = number
  })
}

#------------------------------------------------------------------------------
# Best practices configuration (best-practices.tfvars)
#------------------------------------------------------------------------------
variable "backup" {
  description = "Backup and recovery configuration"
  type = object({
    enabled        = bool
    retention_days = number
  })
}

variable "budget" {
  description = "Cost management budget configuration"
  type = object({
    enabled            = bool
    monthly_amount     = number
    alert_thresholds   = map(number) # e.g. { warning = 50, critical = 80, maximum = 100 }
    notification_email = string
  })
}

variable "policy" {
  description = "Azure Policy assignment configuration"
  type = object({
    enable_security_policies    = bool
    enable_cost_policies        = bool
    enable_operational_policies = bool
  })
}

#------------------------------------------------------------------------------
# Disaster recovery configuration (dr.tfvars)
#------------------------------------------------------------------------------
variable "dr" {
  description = "Disaster recovery configuration"
  type = object({
    enabled             = bool
    replication_enabled = bool
    failover_priority   = number
  })
}
