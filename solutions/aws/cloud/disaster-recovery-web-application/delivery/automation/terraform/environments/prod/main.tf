#------------------------------------------------------------------------------
# DR Web Application - Production Environment
#------------------------------------------------------------------------------
# Primary region deployment for disaster recovery web application with:
# - 3-tier architecture (ALB → EC2 ASG → Aurora Global Database)
# - Cross-region replication to DR region (us-west-2)
# - Route 53 health-based failover
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
# Networking (VPC + Subnets + NAT + Flow Logs)
#------------------------------------------------------------------------------
module "networking" {
  source = "../../modules/networking"

  project = local.project
  network = {
    vpc_cidr           = var.network.vpc_cidr
    enable_nat_gateway = var.network.enable_nat_gateway
    enable_flow_logs   = var.network.enable_flow_logs
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
# Database (Aurora Global Database - Primary)
#------------------------------------------------------------------------------
module "database" {
  source = "../../modules/database"

  project = local.project
  database = {
    is_primary_region           = var.database.is_primary_region
    engine_version              = var.database.engine_version
    database_name               = var.database.database_name
    master_username             = var.database.master_username
    master_password             = var.database.master_password
    instance_class              = var.database.instance_class
    instance_count              = var.database.instance_count
    backup_retention_days       = var.database.backup_retention_days
    backup_window               = var.database.backup_window
    maintenance_window          = var.database.maintenance_window
    enable_deletion_protection  = var.database.enable_deletion_protection
    skip_final_snapshot         = var.database.skip_final_snapshot
    monitoring_interval         = var.database.monitoring_interval
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
# Storage (S3 with Cross-Region Replication)
#------------------------------------------------------------------------------
module "storage" {
  source = "../../modules/storage"

  project = local.project
  storage = {
    enable_versioning                  = var.storage.enable_versioning
    transition_to_ia_days              = var.storage.transition_to_ia_days
    transition_to_glacier_days         = var.storage.transition_to_glacier_days
    noncurrent_version_expiration_days = var.storage.noncurrent_version_expiration_days
    enable_replication                 = var.dr.replication_enabled
    dr_bucket_arn                      = var.dr.replication_enabled ? module.dr.dr_bucket_arn : null
    dr_kms_key_arn                     = var.dr.replication_enabled ? module.dr.dr_kms_key_arn : null
    dr_region                          = var.aws.dr_region
    enable_replication_time_control    = var.storage.enable_replication_time_control
  }
  security = {
    kms_key_arn = module.kms.key_arn
  }
  monitoring = {
    sns_topic_arn = module.monitoring.sns_topic_arn
  }
  common_tags = local.common_tags

  depends_on = [module.dr]
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
    health_check_id         = var.dr.enabled ? module.dr.health_check_id : null
    alb_arn_suffix          = module.compute.alb_arn_suffix
    target_group_arn_suffix = module.compute.target_group_arn_suffix
    asg_name                = module.compute.asg_name
    aurora_cluster_id       = module.database.cluster_id
    s3_bucket_id            = module.storage.bucket_id
    s3_dr_bucket_id         = var.dr.vault_enabled ? module.dr.dr_bucket_id : null
  }
  monitoring = {
    alert_email                  = var.monitoring.alert_email
    alb_5xx_threshold            = var.monitoring.alb_5xx_threshold
    alb_latency_threshold        = var.monitoring.alb_latency_threshold
    aurora_cpu_threshold         = var.monitoring.aurora_cpu_threshold
    aurora_connections_threshold = var.monitoring.aurora_connections_threshold
    rpo_target_ms                = var.dr.rpo_target_minutes * 60 * 1000
  }
  security = {
    kms_key_id = module.kms.key_id
  }
  common_tags = local.common_tags

  depends_on = [module.compute, module.database, module.dr]
}

#------------------------------------------------------------------------------
# Disaster Recovery (Route 53 Failover + Backup + Replication)
#------------------------------------------------------------------------------
module "dr" {
  source = "../../modules/dr"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  project = local.project
  dr = {
    enabled                                  = var.dr.enabled
    vault_enabled                            = var.dr.vault_enabled
    replication_enabled                      = var.dr.replication_enabled
    backup_retention_days                    = var.dr.backup_retention_days
    dr_backup_retention_days                 = var.dr.dr_backup_retention_days
    enable_weekly_backup                     = var.dr.enable_weekly_backup
    weekly_backup_retention_days             = var.dr.weekly_backup_retention_days
    replication_lag_threshold_ms             = var.dr.rpo_target_minutes * 60 * 1000
    vault_kms_deletion_window_days           = var.dr.vault_kms_deletion_window_days
    vault_transition_to_ia_days              = var.dr.vault_transition_to_ia_days
    vault_noncurrent_version_expiration_days = var.dr.vault_noncurrent_version_expiration_days
  }
  dns = {
    hosted_zone_id                 = var.dns.hosted_zone_id
    domain_name                    = var.dns.domain_name
    health_check_path              = var.compute.health_check_path
    health_check_interval          = var.dns.health_check_interval
    health_check_failure_threshold = var.dns.health_check_failure_threshold
  }
  primary = {
    alb_dns_name      = module.compute.alb_dns_name
    alb_zone_id       = module.compute.alb_zone_id
    aurora_cluster_id = module.database.cluster_id
  }
  security = {
    kms_key_arn = module.kms.key_arn
  }
  monitoring = {
    sns_topic_arn = module.monitoring.sns_topic_arn
  }
  common_tags = local.common_tags

  depends_on = [module.compute, module.database]
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
# Database CloudWatch Alarms (cross-module)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${local.name_prefix}-aurora-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.aurora_cpu_threshold
  alarm_description   = "Aurora cluster CPU utilization is too high"
  alarm_actions       = [module.monitoring.sns_topic_arn]
  ok_actions          = [module.monitoring.sns_topic_arn]

  dimensions = {
    DBClusterIdentifier = module.database.cluster_id
  }

  tags = local.common_tags

  depends_on = [module.database, module.monitoring]
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections" {
  alarm_name          = "${local.name_prefix}-aurora-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.aurora_connections_threshold
  alarm_description   = "Aurora cluster connection count is too high"
  alarm_actions       = [module.monitoring.sns_topic_arn]
  ok_actions          = [module.monitoring.sns_topic_arn]

  dimensions = {
    DBClusterIdentifier = module.database.cluster_id
  }

  tags = local.common_tags

  depends_on = [module.database, module.monitoring]
}

#===============================================================================
# CHECK BLOCKS (plan-time validation)
#===============================================================================
check "budget_requires_notification_email" {
  assert {
    condition     = !var.budget.enabled || var.budget.notification_email != ""
    error_message = "budget.notification_email must be set when budget.enabled = true"
  }
}

check "dr_requires_distinct_regions" {
  assert {
    condition     = var.aws.region != var.aws.dr_region
    error_message = "aws.region and aws.dr_region must be different regions"
  }
}
