#------------------------------------------------------------------------------
# IDP Terraform Variables - Grouped Object Pattern
#------------------------------------------------------------------------------
# Variables organized by functional area following EO Framework standards
# Each group uses object type with optional attributes for clean defaults
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration (project.tfvars)
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Short project name used as prefix in all resource names (e.g. 'idp')"
  type        = string
}

variable "env" {
  description = "Environment identifier used in resource names (e.g. 'prod', 'test', 'dr')"
  type        = string
}

variable "solution" {
  description = "Solution identity configuration"
  type = object({
    name          = string
    abbr          = string
    provider_name = string
    category_name = string
  })
}

variable "aws" {
  description = "AWS provider configuration"
  type = object({
    region    = string
    dr_region = optional(string, "us-west-2")
    profile   = optional(string, "")
  })
}

variable "ownership" {
  description = "Ownership and cost tracking"
  type = object({
    cost_center  = string
    owner_email  = string
    project_code = string
  })
}

#------------------------------------------------------------------------------
# Network Configuration (networking.tfvars)
# Only consumed when application.lambda_vpc_enabled = true.
# When VPC mode is off these variables are still declared but the networking
# module is not created (count = 0), so values here are never applied.
#------------------------------------------------------------------------------

variable "vpc" {
  description = "VPC configuration"
  type = object({
    cidr_block              = optional(string, "10.20.0.0/16")
    enable_dns_support      = optional(bool, true)
    enable_dns_hostnames    = optional(bool, true)
    enable_nat_gateway      = optional(bool, false)
    single_nat_gateway      = optional(bool, true)
    enable_flow_logs        = optional(bool, false)
    flow_log_retention_days = optional(number, 14)
  })
  default = {}
}

variable "subnets" {
  description = "Map of subnet configurations keyed by descriptive name ({solution}-{tier}-{az})"
  type = map(object({
    cidr_block        = string
    availability_zone = string
    layer = optional(string, "private")
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Security Configuration (security.tfvars)
#------------------------------------------------------------------------------

variable "security" {
  description = "KMS encryption configuration"
  type = object({
    kms_deletion_window_days = optional(number, 30)
    enable_kms_key_rotation  = optional(bool, true)
  })
  default = {}
}

variable "security_groups" {
  description = "Map of security group configurations (networking.tfvars or security.tfvars)"
  type = map(object({
    description = string
    ingress_cidr = optional(map(object({
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_block  = string
      description = optional(string, "")
    })), {})
    egress_cidr = optional(map(object({
      from_port   = number
      to_port     = number
      ip_protocol = string
      cidr_block  = string
      description = optional(string, "")
    })), {})
    ingress_sg = optional(map(object({
      from_port                 = number
      to_port                   = number
      ip_protocol               = string
      source_security_group_key = string
      description               = optional(string, "")
    })), {})
    egress_sg = optional(map(object({
      from_port                 = number
      to_port                   = number
      ip_protocol               = string
      source_security_group_key = string
      description               = optional(string, "")
    })), {})
  }))
  default = {}
}

#------------------------------------------------------------------------------
# Storage Configuration (storage.tfvars)
#------------------------------------------------------------------------------

variable "storage" {
  description = "S3 document storage configuration"
  type = object({
    # General settings
    force_destroy      = optional(bool, false)
    versioning_enabled = optional(bool, true)
    # Lifecycle transitions
    transition_to_ia_days              = optional(number, 30)
    transition_to_glacier_days         = optional(number, 90)
    document_expiration_days           = optional(number, 365)
    noncurrent_version_expiration_days = optional(number, 30)
    # Direct upload settings
    enable_direct_upload = optional(bool, true)
    cors_allowed_origins = optional(list(string), ["*"])
    # Output bucket
    create_output_bucket   = optional(bool, true)
    output_expiration_days = optional(number, 30)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Database Configuration (database.tfvars)
#------------------------------------------------------------------------------

variable "database" {
  description = "DynamoDB configuration"
  type = object({
    # Capacity mode
    billing_mode       = optional(string, "PAY_PER_REQUEST")
    read_capacity      = optional(number, 5)
    write_capacity     = optional(number, 5)
    gsi_read_capacity  = optional(number, 5)
    gsi_write_capacity = optional(number, 5)
    # Features
    ttl_enabled            = optional(bool, true)
    point_in_time_recovery = optional(bool, true)
    stream_enabled         = optional(bool, false)
    stream_view_type       = optional(string, "NEW_AND_OLD_IMAGES")
    # Auto-scaling (PROVISIONED mode only)
    enable_autoscaling             = optional(bool, true)
    autoscaling_min_read           = optional(number, 5)
    autoscaling_max_read           = optional(number, 100)
    autoscaling_min_write          = optional(number, 5)
    autoscaling_max_write          = optional(number, 100)
    autoscaling_target_utilization = optional(number, 70)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Application Configuration (application.tfvars)
#------------------------------------------------------------------------------

variable "application" {
  description = "Lambda runtime configuration"
  type = object({
    lambda_runtime     = optional(string, "python3.11")
    lambda_vpc_enabled = optional(bool, false)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Lambda Package Configuration
#------------------------------------------------------------------------------

variable "lambda_packages" {
  description = "Paths to Lambda deployment packages"
  type = object({
    # Document processing functions
    start_analysis      = optional(string, "")
    process_textract    = optional(string, "")
    comprehend_analysis = optional(string, "")
    validate_document   = optional(string, "")
    finalize_results    = optional(string, "")
    # Human review functions
    process_review = optional(string, "")
    create_task    = optional(string, "")
    complete_task  = optional(string, "")
    # API functions
    api_upload  = optional(string, "")
    api_status  = optional(string, "")
    api_results = optional(string, "")
    api_list    = optional(string, "")
    api_delete  = optional(string, "")
    api_health  = optional(string, "")
  })
  default = {}
}

variable "lambda_source_hashes" {
  description = "Source code hashes for Lambda packages (for deployment updates)"
  type = object({
    start_analysis      = optional(string, "")
    process_textract    = optional(string, "")
    comprehend_analysis = optional(string, "")
    validate_document   = optional(string, "")
    finalize_results    = optional(string, "")
    process_review      = optional(string, "")
    create_task         = optional(string, "")
    complete_task       = optional(string, "")
    api_upload          = optional(string, "")
    api_status          = optional(string, "")
    api_results         = optional(string, "")
    api_list            = optional(string, "")
    api_delete          = optional(string, "")
    api_health          = optional(string, "")
  })
  default = {}
}

#------------------------------------------------------------------------------
# Textract Configuration (compute.tfvars - AI Services)
#------------------------------------------------------------------------------

variable "textract" {
  description = "Amazon Textract OCR configuration"
  type = object({
    supported_document_types = optional(list(string), ["pdf", "png", "jpg", "jpeg", "tiff"])
    max_file_size_mb         = optional(number, 50)
    confidence_threshold     = optional(number, 80)
    polling_interval_seconds = optional(number, 30)
    max_polling_attempts     = optional(number, 20)
    enable_tables            = optional(bool, true)
    enable_forms             = optional(bool, true)
    enable_queries           = optional(bool, false)
    enable_signatures        = optional(bool, false)
    enable_expense           = optional(bool, false)
    enable_id                = optional(bool, false)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Comprehend Configuration (compute.tfvars - AI Services)
#------------------------------------------------------------------------------

variable "comprehend" {
  description = "Amazon Comprehend NLP configuration"
  type = object({
    enable_pii_detection    = optional(bool, true)
    enable_entity_detection = optional(bool, true)
    enable_key_phrases      = optional(bool, true)
    enable_sentiment        = optional(bool, false)
    language_code           = optional(string, "en")
    pii_entity_types        = optional(list(string), ["ALL"])
  })
  default = {}
}

#------------------------------------------------------------------------------
# Human Review Configuration (compute.tfvars - A2I)
#------------------------------------------------------------------------------

variable "human_review" {
  description = "Amazon A2I human review configuration"
  type = object({
    enabled                   = optional(bool, true)
    use_private_workforce     = optional(bool, true)
    workteam_arn              = optional(string)
    task_price_usd            = optional(number, 0.05)
    task_title                = optional(string, "Document Review Task")
    task_description          = optional(string, "Review the extracted document data and verify accuracy")
    task_count                = optional(number, 1)
    task_availability_seconds = optional(number, 43200)
    confidence_threshold      = optional(number, 80)
    custom_ui_template        = optional(string)
  })
  default = {}
}

#------------------------------------------------------------------------------
# API Configuration (application.tfvars)
#------------------------------------------------------------------------------

variable "api" {
  description = "API Gateway configuration"
  type = object({
    version                = optional(string, "1.0.0")
    stage_name             = optional(string, "v1")
    endpoint_type          = optional(string, "REGIONAL")
    enable_cors            = optional(bool, true)
    max_file_size_mb       = optional(number, 50)
    default_page_size      = optional(number, 20)
    throttling_burst_limit = optional(number, 1000)
    throttling_rate_limit  = optional(number, 500)
    allowed_content_types = optional(list(string), [
      "application/pdf",
      "image/png",
      "image/jpeg",
      "image/tiff"
    ])
  })
  default = {}
}

#------------------------------------------------------------------------------
# Authentication Configuration (security.tfvars - Cognito)
#------------------------------------------------------------------------------

variable "auth" {
  description = "Cognito authentication configuration"
  type = object({
    enabled                    = optional(bool, true)
    username_attributes        = optional(list(string), ["email"])
    auto_verified_attributes   = optional(list(string), ["email"])
    password_minimum_length    = optional(number, 12)
    password_require_lowercase = optional(bool, true)
    password_require_numbers   = optional(bool, true)
    password_require_symbols   = optional(bool, true)
    password_require_uppercase = optional(bool, true)
    mfa_configuration          = optional(string, "OPTIONAL")
    advanced_security_mode     = optional(string, "AUDIT")
    domain                     = optional(string)
    callback_urls              = optional(list(string), [])
    logout_urls                = optional(list(string), [])
  })
  default = {}
}

#------------------------------------------------------------------------------
# Logging Configuration (monitoring.tfvars)
#------------------------------------------------------------------------------

variable "logging" {
  description = "CloudWatch logging configuration"
  type = object({
    retention_days           = optional(number, 30)
    step_functions_log_level = optional(string, "ERROR")
    api_gateway_log_level    = optional(string, "INFO")
    data_trace_enabled       = optional(bool, false)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Monitoring Configuration (monitoring.tfvars)
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring and alerting configuration"
  type = object({
    xray_enabled  = optional(bool, true)
    enable_alarms = optional(bool, true)
    sns_topic_arn = optional(string)
    # API Gateway thresholds
    api_error_threshold = optional(number, 10)
    api_4xx_threshold   = optional(number, 100)
    api_latency_p95_ms  = optional(number, 2000)
    # Step Functions thresholds
    sfn_failure_threshold = optional(number, 5)
    # Lambda thresholds
    lambda_error_rate_percent = optional(number, 5)
    lambda_duration_p95_ms    = optional(number, 60000)
  })
  default = {}
}

#------------------------------------------------------------------------------
# DR Configuration (dr.tfvars)
#------------------------------------------------------------------------------

variable "dr" {
  description = "Disaster Recovery configuration - strategy, replication, vault, and backup settings"
  type = object({
    # Master DR toggle and strategy
    enabled       = optional(bool, false)
    strategy      = optional(string, "ACTIVE_PASSIVE") # ACTIVE_PASSIVE, ACTIVE_ACTIVE, BACKUP_ONLY
    rto_minutes   = optional(number, 240)              # Recovery Time Objective
    rpo_minutes   = optional(number, 60)               # Recovery Point Objective
    failover_mode = optional(string, "manual")         # manual, automatic

    # Cross-region replication settings
    replication_enabled             = optional(bool, false)
    storage_replication_class       = optional(string, "STANDARD")
    enable_replication_time_control = optional(bool, true)

    # DR vault settings
    vault_enabled                            = optional(bool, false)
    vault_kms_deletion_window_days           = optional(number, 30)
    vault_transition_to_ia_days              = optional(number, 30)
    vault_noncurrent_version_expiration_days = optional(number, 90)
    vault_enable_lock                        = optional(bool, false)

    # DR backup settings
    backup_retention_days        = optional(number, 30)
    backup_local_retention_days  = optional(number, 7)
    enable_weekly_backup         = optional(bool, true)
    weekly_backup_retention_days = optional(number, 90)

    # DR operations
    test_schedule      = optional(string, "")
    notification_email = optional(string, "")
  })
  default = {
    enabled = false
  }
}

#------------------------------------------------------------------------------
# Best Practices - Cost Optimization (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "budget" {
  description = "AWS Budgets configuration for cost management"
  type = object({
    enabled               = optional(bool, true)
    monthly_amount        = optional(number, 1500)
    alert_thresholds      = optional(list(number), [50, 80, 100])
    enable_forecast_alert = optional(bool, true)
    alert_emails          = optional(list(string), [])
  })
  default = {
    enabled = false
  }
}

#------------------------------------------------------------------------------
# Best Practices - Operational Excellence (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "config_rules" {
  description = "AWS Config rules for compliance monitoring"
  type = object({
    enabled                  = optional(bool, true)
    enable_recorder          = optional(bool, true)
    retention_days           = optional(number, 365)
    enable_security_rules    = optional(bool, true)
    enable_reliability_rules = optional(bool, true)
  })
  default = {
    enabled = false
  }
}

#------------------------------------------------------------------------------
# Best Practices - Security (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "guardduty" {
  description = "GuardDuty threat detection configuration"
  type = object({
    enabled                   = optional(bool, true)
    enable_s3_protection      = optional(bool, true)
    enable_malware_protection = optional(bool, true)
    severity_threshold        = optional(number, 7)
  })
  default = {
    enabled = false
  }
}
