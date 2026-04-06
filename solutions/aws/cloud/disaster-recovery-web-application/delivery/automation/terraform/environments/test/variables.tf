#------------------------------------------------------------------------------
# DR Web Application - Test Environment Variables
#------------------------------------------------------------------------------
# Simplified variable set for test environment (no DR features)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Project Configuration (project.tfvars)
#------------------------------------------------------------------------------

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
    dr_region = optional(string, "")
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
#------------------------------------------------------------------------------

variable "network" {
  description = "VPC network configuration"
  type = object({
    vpc_cidr              = string
    enable_nat_gateway    = optional(bool, true)
    enable_flow_logs      = optional(bool, false)
    public_subnet_cidrs   = optional(list(string), ["10.100.1.0/24", "10.100.2.0/24"])
    private_subnet_cidrs  = optional(list(string), ["10.100.10.0/24", "10.100.11.0/24"])
    database_subnet_cidrs = optional(list(string), ["10.100.20.0/24", "10.100.21.0/24"])
  })
}

#------------------------------------------------------------------------------
# Compute Configuration (compute.tfvars)
#------------------------------------------------------------------------------

variable "compute" {
  description = "EC2 and ASG configuration"
  type = object({
    instance_type              = optional(string, "t3.small")
    ami_id                     = optional(string, "")
    asg_min_size               = optional(number, 1)
    asg_max_size               = optional(number, 4)
    asg_desired_capacity       = optional(number, 1)
    root_volume_size           = optional(number, 20)
    app_port                   = optional(number, 80)
    health_check_path          = optional(string, "/health")
    ssl_certificate_arn        = optional(string, "")
    enable_deletion_protection = optional(bool, false)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Database Configuration (database.tfvars)
#------------------------------------------------------------------------------

variable "database" {
  description = "Aurora database configuration"
  type = object({
    engine_version              = optional(string, "8.0.mysql_aurora.3.04.0")
    database_name               = optional(string, "webapp")
    master_username             = optional(string, "admin")
    master_password             = string
    instance_class              = optional(string, "db.t3.medium")
    instance_count              = optional(number, 1)
    backup_retention_days       = optional(number, 1)
    backup_window               = optional(string, "03:00-04:00")
    maintenance_window          = optional(string, "sun:04:00-sun:05:00")
    enable_deletion_protection  = optional(bool, false)
    skip_final_snapshot         = optional(bool, true)
    monitoring_interval         = optional(number, 0)
    enable_performance_insights = optional(bool, false)
    is_primary_region           = optional(bool, true)
  })
}

#------------------------------------------------------------------------------
# Storage Configuration (storage.tfvars)
#------------------------------------------------------------------------------

variable "storage" {
  description = "S3 storage configuration"
  type = object({
    enable_versioning                  = optional(bool, true)
    transition_to_ia_days              = optional(number, 90)
    transition_to_glacier_days         = optional(number, 180)
    noncurrent_version_expiration_days = optional(number, 7)
    enable_replication_time_control    = optional(bool, false)
    replication_latency_threshold      = optional(number, 0)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Security Configuration (security.tfvars)
#------------------------------------------------------------------------------

variable "security" {
  description = "Security configuration"
  type = object({
    kms_deletion_window_days = optional(number, 7)
    enable_kms_key_rotation  = optional(bool, true)
    enable_waf               = optional(bool, false)
    waf_rate_limit           = optional(number, 1000)
  })
  default = {}
}

#------------------------------------------------------------------------------
# DNS Configuration (dns.tfvars) - Minimal for test
#------------------------------------------------------------------------------

variable "dns" {
  description = "Route 53 DNS configuration (minimal for test)"
  type = object({
    hosted_zone_id                 = optional(string, "")
    domain_name                    = optional(string, "")
    health_check_interval          = optional(number, 30)
    health_check_failure_threshold = optional(number, 3)
  })
  default = {}
}

#------------------------------------------------------------------------------
# DR Configuration (dr.tfvars) - Disabled for test
#------------------------------------------------------------------------------

variable "dr" {
  description = "Disaster recovery configuration (disabled for test)"
  type = object({
    enabled                              = optional(bool, false)
    vault_enabled                        = optional(bool, false)
    replication_enabled                  = optional(bool, false)
    rto_target_minutes                   = optional(number, 0)
    rpo_target_minutes                   = optional(number, 0)
    backup_retention_days                = optional(number, 7)
    dr_backup_retention_days             = optional(number, 0)
    enable_weekly_backup                 = optional(bool, false)
    weekly_backup_retention_days         = optional(number, 0)
    enable_continuous_backup             = optional(bool, false)
    vault_kms_deletion_window_days       = optional(number, 7)
    vault_transition_to_ia_days          = optional(number, 30)
    vault_noncurrent_version_expiration_days = optional(number, 7)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Monitoring Configuration (monitoring.tfvars)
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring configuration (relaxed thresholds for test)"
  type = object({
    alert_email                  = optional(string, "")
    alb_5xx_threshold            = optional(number, 20)
    alb_latency_threshold        = optional(number, 5.0)
    aurora_cpu_threshold         = optional(number, 90)
    aurora_connections_threshold = optional(number, 50)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices (best-practices.tfvars) - Minimal for test
#------------------------------------------------------------------------------


#==============================================================================
# BEST PRACTICES (config/best-practices.tfvars)
#==============================================================================

#------------------------------------------------------------------------------
# Budget (best-practices.tfvars)
#------------------------------------------------------------------------------
variable "budget" {
  description = "AWS Budgets configuration"
  type = object({
    enabled               = optional(bool, false)
    monthly_amount        = optional(number, 1000)
    alert_thresholds      = optional(list(number), [50, 80, 100])
    alert_emails          = optional(list(string), [])
    enable_forecast_alert = optional(bool, true)
    forecast_threshold    = optional(number, 100)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Config Rules (best-practices.tfvars)
#------------------------------------------------------------------------------
variable "config_rules" {
  description = "AWS Config rules configuration"
  type = object({
    enabled                  = optional(bool, false)
    enable_recorder          = optional(bool, true)
    retention_days           = optional(number, 365)
    enable_security_rules    = optional(bool, true)
    enable_reliability_rules = optional(bool, true)
    enable_operational_rules = optional(bool, true)
    enable_cost_rules        = optional(bool, true)
  })
  default = {}
}

#------------------------------------------------------------------------------
# GuardDuty (best-practices.tfvars)
#------------------------------------------------------------------------------
variable "guardduty" {
  description = "GuardDuty threat detection configuration"
  type = object({
    enabled                   = optional(bool, false)
    enable_malware_protection = optional(bool, true)
    enable_eks_protection     = optional(bool, false)
    severity_threshold        = optional(number, 7)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Backup (best-practices.tfvars)
#------------------------------------------------------------------------------
variable "backup" {
  description = "AWS Backup configuration"
  type = object({
    enabled                    = optional(bool, false)
    daily_retention            = optional(number, 30)
    weekly_retention           = optional(number, 90)
    monthly_retention          = optional(number, 365)
    enable_cross_region        = optional(bool, false)
    enable_vault_lock          = optional(bool, false)
    vault_lock_min_retention   = optional(number, 7)
    vault_lock_max_retention   = optional(number, 365)
    vault_lock_changeable_days = optional(number, 3)
  })
  default = {}
}
