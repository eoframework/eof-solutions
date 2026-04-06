#------------------------------------------------------------------------------
# Cloud Migration - DR Environment
#------------------------------------------------------------------------------
# Standby DR deployment for cloud migration solution:
# - Warm standby VPC with VPN connectivity to on-premises
# - Minimal compute (scaled down or pilot light)
# - RDS read replica or restored backup
# - S3 with cross-region replication destination
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  environment = basename(path.module)
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
    Region       = var.aws.region
    ManagedBy    = "terraform"
    CostCenter   = var.ownership.cost_center
    Owner        = var.ownership.owner_email
    ProjectCode  = var.ownership.project_code
    Purpose      = "DisasterRecovery"
    Standby      = "true"
  }
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#===============================================================================
# FOUNDATION
#===============================================================================
#------------------------------------------------------------------------------
# KMS Key (DR Region)
#------------------------------------------------------------------------------
module "kms" {
  source = "../../modules/kms"

  name_prefix             = local.name_prefix
  deletion_window_in_days = var.security.kms_deletion_window_days
  enable_key_rotation     = var.security.enable_kms_key_rotation
  tags                    = local.common_tags
}

#------------------------------------------------------------------------------
# Networking (VPC + Subnets + NAT + VPN + Flow Logs)
#------------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  project = local.project
  network = {
    vpc_cidr                = var.network.vpc_cidr
    enable_nat_gateway      = var.network.enable_nat_gateway
    enable_flow_logs        = var.network.enable_flow_logs
    enable_site_to_site_vpn = var.network.enable_site_to_site_vpn
    on_prem_cidr            = var.network.on_prem_cidr
  }
  kms_key_arn = module.kms.key_arn
  common_tags = local.common_tags
}

#------------------------------------------------------------------------------
# Security (WAF + Security Groups)
#------------------------------------------------------------------------------
module "security" {
  source = "../../modules/security"

  project = local.project
  security = {
    enable_waf     = var.security.enable_waf
    waf_rate_limit = var.security.waf_rate_limit
  }
  network = {
    vpc_id   = module.networking.vpc_id
    app_port = var.compute.app_port
  }
  common_tags = local.common_tags
}

#------------------------------------------------------------------------------
# Compute (ALB + ASG - standby capacity)
#------------------------------------------------------------------------------
module "compute" {
  source = "../../modules/compute"

  project = local.project
  network = {
    vpc_id             = module.networking.vpc_id
    public_subnet_ids  = module.networking.public_subnet_ids
    private_subnet_ids = module.networking.private_subnet_ids
  }
  compute = {
    instance_type              = var.compute.instance_type
    ami_id                     = var.compute.ami_id
    asg_min_size               = var.compute.asg_min_size
    asg_max_size               = var.compute.asg_max_size
    asg_desired_capacity       = var.compute.asg_desired_capacity
    root_volume_size           = var.compute.root_volume_size
    data_volume_size           = var.compute.data_volume_size
    app_port                   = var.compute.app_port
    health_check_path          = var.compute.health_check_path
    ssl_certificate_arn        = var.compute.ssl_certificate_arn
    enable_deletion_protection = var.compute.enable_deletion_protection
  }
  security = {
    alb_security_group_id = module.security.alb_security_group_id
    app_security_group_id = module.security.app_security_group_id
    kms_key_arn           = module.kms.key_arn
  }
  common_tags = local.common_tags
}

#===============================================================================
# CORE SOLUTION
#===============================================================================
#------------------------------------------------------------------------------
# Database (RDS standby)
#------------------------------------------------------------------------------
module "database" {
  source = "../../modules/database"

  project = local.project
  database = {
    engine                      = var.database.engine
    engine_version              = var.database.engine_version
    database_name               = var.database.database_name
    master_username             = var.database.master_username
    master_password             = var.database.master_password
    instance_class              = var.database.instance_class
    multi_az                    = var.database.multi_az
    storage_size                = var.database.allocated_storage
    backup_retention_days       = var.database.backup_retention_days
    backup_window               = var.database.backup_window
    maintenance_window          = var.database.maintenance_window
    enable_deletion_protection  = var.database.enable_deletion_protection
    skip_final_snapshot         = var.database.skip_final_snapshot
    enable_performance_insights = var.database.enable_performance_insights
  }
  network = {
    database_subnet_ids = module.networking.database_subnet_ids
  }
  security = {
    db_security_group_id = module.security.db_security_group_id
    kms_key_arn          = module.kms.key_arn
  }
  common_tags = local.common_tags

  depends_on = [module.security]
}

#------------------------------------------------------------------------------
# Storage (S3 - Replication destination from primary)
#------------------------------------------------------------------------------
module "storage" {
  source = "../../modules/storage"

  project = local.project
  storage = {
    enable_versioning                  = var.storage.enable_versioning
    transition_to_ia_days              = var.storage.transition_to_ia_days
    transition_to_glacier_days         = var.storage.transition_to_glacier_days
    noncurrent_version_expiration_days = var.storage.noncurrent_version_expiration_days
    enable_replication                 = false  # DR region receives, does not replicate
  }
  security = {
    kms_key_arn = module.kms.key_arn
  }
  common_tags = local.common_tags
}

#------------------------------------------------------------------------------
# Best Practices (Budgets + Config Rules + GuardDuty + Backup)
#------------------------------------------------------------------------------
module "best_practices" {
  source = "../../modules/best-practices"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix   = local.name_prefix
  environment   = local.environment
  kms_key_arn   = module.kms.key_arn
  sns_topic_arn = module.monitoring.sns_topic_arn
  common_tags   = local.common_tags

  budget = {
    enabled               = var.budget.enabled
    monthly_amount        = var.budget.monthly_amount
    alert_thresholds      = var.budget.alert_thresholds
    alert_emails          = var.budget.alert_emails
    enable_forecast_alert = var.budget.enable_forecast_alert
    forecast_threshold    = var.budget.forecast_threshold
  }

  config_rules = {
    enabled                  = var.config_rules.enabled
    enable_recorder          = var.config_rules.enable_recorder
    retention_days           = var.config_rules.retention_days
    enable_security_rules    = var.config_rules.enable_security_rules
    enable_reliability_rules = var.config_rules.enable_reliability_rules
    enable_operational_rules = var.config_rules.enable_operational_rules
    enable_cost_rules        = var.config_rules.enable_cost_rules
  }

  guardduty_enhanced = {
    enabled                   = var.guardduty.enabled
    enable_malware_protection = var.guardduty.enable_malware_protection
    enable_eks_protection     = var.guardduty.enable_eks_protection
    severity_threshold        = var.guardduty.severity_threshold
  }

  backup = {
    enabled                    = var.backup.enabled
    daily_retention            = var.backup.daily_retention
    enable_weekly              = true
    weekly_retention           = var.backup.weekly_retention
    enable_monthly             = true
    monthly_retention          = var.backup.monthly_retention
    enable_cross_region        = var.backup.enable_cross_region
    enable_vault_lock          = var.backup.enable_vault_lock
    vault_lock_min_retention   = var.backup.vault_lock_min_retention
    vault_lock_max_retention   = var.backup.vault_lock_max_retention
    vault_lock_changeable_days = var.backup.vault_lock_changeable_days
  }

  depends_on = [module.monitoring]
}

#===============================================================================
# CHECK BLOCKS (plan-time validation)
#===============================================================================
check "budget_requires_notification_email" {
  assert {
    condition     = !var.budget.enabled || length(var.budget.alert_emails) > 0
    error_message = "budget.alert_emails must contain at least one address when budget.enabled = true"
  }
}
