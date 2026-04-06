#------------------------------------------------------------------------------
# Cloud Migration - Production Environment
#------------------------------------------------------------------------------
# AWS landing zone for on-premises to cloud migration:
# - Multi-AZ VPC with Site-to-Site VPN for hybrid connectivity
# - ALB + EC2 ASG for migrated applications
# - RDS Multi-AZ for migrated databases
# - S3 for application data
# - RTO: 4 hours, RPO: 1 hour
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
# KMS Key
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
# Compute (ALB + ASG)
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
# Database (RDS Multi-AZ)
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
# Storage (S3)
#------------------------------------------------------------------------------
module "storage" {
  source = "../../modules/storage"

  project = local.project
  storage = {
    enable_versioning                  = var.storage.enable_versioning
    transition_to_ia_days              = var.storage.transition_to_ia_days
    transition_to_glacier_days         = var.storage.transition_to_glacier_days
    noncurrent_version_expiration_days = var.storage.noncurrent_version_expiration_days
    enable_replication                 = var.storage.enable_replication
    dr_region                          = var.aws.dr_region
  }
  security = {
    kms_key_arn = module.kms.key_arn
  }
  common_tags = local.common_tags
}

#===============================================================================
# OPERATIONS
#===============================================================================
#------------------------------------------------------------------------------
# Monitoring (CloudWatch Dashboard + Alarms)
#------------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/monitoring"

  project = local.project
  aws = {
    region = var.aws.region
  }
  resources = {
    alb_arn_suffix          = module.compute.alb_arn_suffix
    target_group_arn_suffix = module.compute.target_group_arn_suffix
    asg_name                = module.compute.asg_name
    rds_instance_id         = module.database.db_instance_id
    s3_bucket_id            = module.storage.bucket_id
  }
  monitoring = {
    alert_email               = var.monitoring.alert_email
    ec2_cpu_threshold         = var.monitoring.ec2_cpu_threshold
    rds_cpu_threshold         = var.monitoring.rds_cpu_threshold
    rds_connections_threshold = var.monitoring.rds_connections_threshold
    alb_5xx_threshold         = var.monitoring.alb_5xx_threshold
    log_retention_days        = var.monitoring.log_retention_days
  }
  security = {
    kms_key_id = module.kms.key_id
  }
  common_tags = local.common_tags

  depends_on = [module.compute, module.database, module.storage]
}

#===============================================================================
# INTEGRATIONS
#===============================================================================
#------------------------------------------------------------------------------
# WAF Web ACL Association
#------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.security.enable_waf ? 1 : 0

  resource_arn = module.compute.alb_arn
  web_acl_arn  = module.security.waf_web_acl_arn

  depends_on = [module.security, module.compute]
}

#------------------------------------------------------------------------------
# RDS CloudWatch Alarms (cross-module)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name_prefix}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.rds_cpu_threshold
  alarm_description   = "RDS CPU utilization is too high"
  alarm_actions       = [module.monitoring.sns_topic_arn]
  ok_actions          = [module.monitoring.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = module.database.db_instance_id
  }

  tags = local.common_tags

  depends_on = [module.database, module.monitoring]
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.rds_connections_threshold
  alarm_description   = "RDS connection count is too high"
  alarm_actions       = [module.monitoring.sns_topic_arn]
  ok_actions          = [module.monitoring.sns_topic_arn]

  dimensions = {
    DBInstanceIdentifier = module.database.db_instance_id
  }

  tags = local.common_tags

  depends_on = [module.database, module.monitoring]
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

check "dr_requires_distinct_regions" {
  assert {
    condition     = var.aws.region != var.aws.dr_region
    error_message = "aws.region and aws.dr_region must be different regions"
  }
}
