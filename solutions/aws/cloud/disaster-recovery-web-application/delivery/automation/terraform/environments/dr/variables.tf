#------------------------------------------------------------------------------
# DR Web Application - DR Environment Variables
#------------------------------------------------------------------------------
# Secondary region deployment with standby capacity
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
    region    = string           # DR region (us-west-2)
    dr_region = optional(string) # Primary region (us-east-1)
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
    enable_flow_logs      = optional(bool, true)
    public_subnet_cidrs   = optional(list(string), ["10.1.1.0/24", "10.1.2.0/24"])
    private_subnet_cidrs  = optional(list(string), ["10.1.10.0/24", "10.1.11.0/24"])
    database_subnet_cidrs = optional(list(string), ["10.1.20.0/24", "10.1.21.0/24"])
  })
}

#------------------------------------------------------------------------------
# Compute Configuration (compute.tfvars)
#------------------------------------------------------------------------------

variable "compute" {
  description = "EC2 and ASG configuration"
  type = object({
    instance_type              = optional(string, "t3.medium")
    ami_id                     = optional(string, "")
    asg_min_size               = optional(number, 0)  # Pilot light - zero instances
    asg_max_size               = optional(number, 10)
    asg_desired_capacity       = optional(number, 1)  # Scale up on failover
    root_volume_size           = optional(number, 30)
    app_port                   = optional(number, 80)
    health_check_path          = optional(string, "/health")
    ssl_certificate_arn        = optional(string, "")
    enable_deletion_protection = optional(bool, true)
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
    instance_class              = optional(string, "db.r6g.large")
    instance_count              = optional(number, 2)
    backup_retention_days       = optional(number, 7)
    backup_window               = optional(string, "03:00-04:00")
    maintenance_window          = optional(string, "sun:04:00-sun:05:00")
    enable_deletion_protection  = optional(bool, true)
    skip_final_snapshot         = optional(bool, false)
    monitoring_interval         = optional(number, 60)
    enable_performance_insights = optional(bool, true)
    is_primary_region           = optional(bool, false)  # DR is secondary
  })
}

#------------------------------------------------------------------------------
# Storage Configuration (storage.tfvars)
#------------------------------------------------------------------------------

variable "storage" {
  description = "S3 storage configuration"
  type = object({
    enable_versioning                  = optional(bool, true)
    transition_to_ia_days              = optional(number, 30)
    transition_to_glacier_days         = optional(number, 90)
    noncurrent_version_expiration_days = optional(number, 30)
    enable_replication_time_control    = optional(bool, true)
    replication_latency_threshold      = optional(number, 900)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Security Configuration (security.tfvars)
#------------------------------------------------------------------------------

variable "security" {
  description = "Security configuration"
  type = object({
    kms_deletion_window_days = optional(number, 30)
    enable_kms_key_rotation  = optional(bool, true)
    enable_waf               = optional(bool, false)  # WAF disabled in DR until failover
    waf_rate_limit           = optional(number, 2000)
  })
  default = {}
}

#------------------------------------------------------------------------------
# DNS Configuration (dns.tfvars)
#------------------------------------------------------------------------------

variable "dns" {
  description = "Route 53 DNS configuration for failover"
  type = object({
    hosted_zone_id                 = optional(string, "")
    domain_name                    = optional(string, "")
    health_check_interval          = optional(number, 30)
    health_check_failure_threshold = optional(number, 3)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Disaster Recovery Configuration (dr.tfvars)
#------------------------------------------------------------------------------

variable "dr" {
  description = "Disaster recovery configuration"
  type = object({
    enabled                              = optional(bool, true)
    vault_enabled                        = optional(bool, true)
    replication_enabled                  = optional(bool, false)  # DR receives replicas
    rto_target_minutes                   = optional(number, 240)
    rpo_target_minutes                   = optional(number, 60)
    backup_retention_days                = optional(number, 30)
    dr_backup_retention_days             = optional(number, 90)
    enable_weekly_backup                 = optional(bool, true)
    weekly_backup_retention_days         = optional(number, 90)
    enable_continuous_backup             = optional(bool, false)
    vault_kms_deletion_window_days       = optional(number, 30)
    vault_transition_to_ia_days          = optional(number, 30)
    vault_noncurrent_version_expiration_days = optional(number, 30)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Monitoring Configuration (monitoring.tfvars)
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring and alerting configuration"
  type = object({
    alert_email                  = optional(string, "")
    alb_5xx_threshold            = optional(number, 10)
    alb_latency_threshold        = optional(number, 2.0)
    aurora_cpu_threshold         = optional(number, 80)
    aurora_connections_threshold = optional(number, 100)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices (best-practices.tfvars)
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
