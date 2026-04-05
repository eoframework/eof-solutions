#------------------------------------------------------------------------------
# Cloud Migration - Production Environment Variables
#------------------------------------------------------------------------------
# Variables organized by functional area following EO Framework standards
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
#------------------------------------------------------------------------------

variable "network" {
  description = "VPC network configuration"
  type = object({
    vpc_cidr                 = string
    enable_nat_gateway       = optional(bool, true)
    enable_flow_logs         = optional(bool, true)
    public_subnet_cidrs      = optional(list(string), ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"])
    private_subnet_cidrs     = optional(list(string), ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"])
    database_subnet_cidrs    = optional(list(string), ["10.0.20.0/24", "10.0.21.0/24", "10.0.22.0/24"])
    transit_gateway_enabled  = optional(bool, true)
    enable_direct_connect    = optional(bool, true)
    direct_connect_bandwidth = optional(string, "1Gbps")
    on_prem_cidr             = optional(string, "192.168.0.0/16")
    enable_site_to_site_vpn  = optional(bool, true)
  })
}

#------------------------------------------------------------------------------
# Compute Configuration (compute.tfvars)
#------------------------------------------------------------------------------

variable "compute" {
  description = "EC2 and ASG configuration"
  type = object({
    instance_type              = optional(string, "m5.large")
    ami_id                     = optional(string, "")
    asg_min_size               = optional(number, 2)
    asg_max_size               = optional(number, 20)
    asg_desired_capacity       = optional(number, 4)
    root_volume_size           = optional(number, 50)
    data_volume_size           = optional(number, 100)
    app_port                   = optional(number, 443)
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
  description = "RDS database configuration"
  type = object({
    engine                      = optional(string, "mysql")
    engine_version              = optional(string, "8.0.35")
    database_name               = optional(string, "appdb")
    master_username             = optional(string, "admin")
    master_password             = string
    instance_class              = optional(string, "db.m5.large")
    multi_az                    = optional(bool, true)
    allocated_storage           = optional(number, 100)
    max_allocated_storage       = optional(number, 500)
    backup_retention_days       = optional(number, 7)
    backup_window               = optional(string, "03:00-04:00")
    maintenance_window          = optional(string, "sun:04:00-sun:05:00")
    enable_deletion_protection  = optional(bool, true)
    skip_final_snapshot         = optional(bool, false)
    enable_performance_insights = optional(bool, true)
    enable_read_replica         = optional(bool, true)
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
    enable_replication                 = optional(bool, true)
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
    enable_waf               = optional(bool, true)
    waf_rate_limit           = optional(number, 5000)
    enable_guard_duty        = optional(bool, true)
    enable_security_hub      = optional(bool, true)
    enable_config            = optional(bool, true)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Migration Configuration (migration.tfvars)
#------------------------------------------------------------------------------

variable "migration" {
  description = "AWS Migration services configuration"
  type = object({
    dms_instance_class          = optional(string, "dms.r5.large")
    dms_storage_gb              = optional(number, 100)
    mgn_replication_server_type = optional(string, "t3.small")
    mgn_staging_disk_type       = optional(string, "gp3")
  })
  default = {}
}

#------------------------------------------------------------------------------
# Disaster Recovery Configuration (dr.tfvars)
#------------------------------------------------------------------------------

variable "dr" {
  description = "Disaster recovery configuration"
  type = object({
    enabled                      = optional(bool, true)
    vault_enabled                = optional(bool, true)
    replication_enabled          = optional(bool, true)
    rto_target_minutes           = optional(number, 240)
    rpo_target_minutes           = optional(number, 60)
    backup_retention_days        = optional(number, 30)
    dr_backup_retention_days     = optional(number, 90)
    enable_weekly_backup         = optional(bool, true)
    weekly_backup_retention_days = optional(number, 90)
    vault_kms_deletion_window_days = optional(number, 30)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Monitoring Configuration (monitoring.tfvars)
#------------------------------------------------------------------------------

variable "monitoring" {
  description = "Monitoring and alerting configuration"
  type = object({
    alert_email              = optional(string, "")
    enable_cloudwatch_agent  = optional(bool, true)
    log_retention_days       = optional(number, 90)
    ec2_cpu_threshold        = optional(number, 80)
    rds_cpu_threshold        = optional(number, 80)
    rds_connections_threshold = optional(number, 200)
    alb_5xx_threshold        = optional(number, 10)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices - Budget (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "budget" {
  description = "AWS Budgets configuration"
  type = object({
    enabled            = optional(bool, true)
    monthly_amount     = optional(number, 15000)
    alert_thresholds   = optional(list(number), [50, 80, 100])
    notification_email = optional(string, "")
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices - Config Rules (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "config_rules" {
  description = "AWS Config rules for compliance"
  type = object({
    enabled             = optional(bool, true)
    s3_encryption_check  = optional(bool, true)
    ebs_encryption_check = optional(bool, true)
    rds_encryption_check = optional(bool, true)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices - GuardDuty (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "guardduty" {
  description = "GuardDuty threat detection"
  type = object({
    enabled = optional(bool, true)
  })
  default = {}
}

#------------------------------------------------------------------------------
# Best Practices - Backup (best-practices.tfvars)
#------------------------------------------------------------------------------

variable "backup" {
  description = "AWS Backup configuration"
  type = object({
    enabled           = optional(bool, true)
    daily_retention   = optional(number, 30)
    weekly_retention  = optional(number, 90)
    monthly_retention = optional(number, 365)
    enable_vault_lock = optional(bool, false)
  })
  default = {}
}
