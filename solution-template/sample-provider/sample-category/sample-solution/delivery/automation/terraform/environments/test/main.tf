#------------------------------------------------------------------------------
# Sample Solution Test Environment
#------------------------------------------------------------------------------
# Test deployment with reduced resources for development and testing:
# - VPC, ALB, ASG (core infrastructure)
# - RDS single-AZ (database tier)
# - ElastiCache Redis (caching tier)
# - Reduced security features (no WAF, GuardDuty optional)
# - CloudWatch monitoring with fewer alarms
# - No DR replication (test data doesn't need DR)
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Locals
#------------------------------------------------------------------------------
locals {
  environment = basename(path.module)
  name_prefix = "${var.solution.abbr}-${local.environment}"

  # Environment display name mapping
  env_display_name = {
    prod = "Production"
    test = "Test"
    dr   = "Disaster Recovery"
  }

  #----------------------------------------------------------------------------
  # Shared Configuration Objects
  #----------------------------------------------------------------------------
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
# CONFIGURATION CHECKS - Validate variable combinations at plan time
#===============================================================================

check "budget_requires_alert_emails" {
  assert {
    condition     = !var.budget.enabled || length(var.budget.alert_emails) > 0
    error_message = "budget.alert_emails must contain at least one address when budget.enabled is true."
  }
}

check "regions_are_distinct" {
  assert {
    condition     = var.aws.region != try(var.aws.dr_region, "")
    error_message = "aws.region and aws.dr_region must be different regions."
  }
}

#===============================================================================
# FOUNDATION - Core infrastructure that other modules depend on
#===============================================================================
#------------------------------------------------------------------------------
# Core Infrastructure (VPC, ALB, ASG)
#------------------------------------------------------------------------------
module "core" {
  source = "../../modules/solution/core"

  name_prefix     = local.name_prefix
  project_name    = var.solution.name
  environment     = local.environment
  additional_tags = local.common_tags
  network         = var.network
  security        = var.security
  compute         = var.compute
  alb             = var.alb
  application     = var.application
  kms_key_arn     = module.security.kms_key_arn
}

#------------------------------------------------------------------------------
# Security (KMS, optional WAF/GuardDuty - WAF association in INTEGRATIONS)
#------------------------------------------------------------------------------
module "security" {
  source = "../../modules/solution/security"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
  security    = var.security
}

#===============================================================================
# CORE SOLUTION - Primary solution components
#===============================================================================
#------------------------------------------------------------------------------
# Database (RDS - alarms created in INTEGRATIONS section)
#------------------------------------------------------------------------------
module "database" {
  source = "../../modules/solution/database"

  name_prefix          = local.name_prefix
  common_tags          = local.common_tags
  environment          = local.environment
  db_subnet_group_name = module.core.db_subnet_group_name
  security_group_ids   = [module.core.database_security_group_id]
  kms_key_arn          = module.security.kms_key_arn
  database             = var.database
}

#------------------------------------------------------------------------------
# Cache (ElastiCache Redis - alarms created in INTEGRATIONS section)
#------------------------------------------------------------------------------
module "cache" {
  source = "../../modules/solution/cache"
  count  = var.cache.enabled ? 1 : 0

  name_prefix                   = local.name_prefix
  common_tags                   = local.common_tags
  elasticache_subnet_group_name = module.core.elasticache_subnet_group_name
  security_group_ids            = [module.core.cache_security_group_id]
  kms_key_arn                   = module.security.kms_key_arn
  cache                         = var.cache
}

#===============================================================================
# OPERATIONS - Monitoring, compliance, and DR
#===============================================================================
#------------------------------------------------------------------------------
# Monitoring (CloudWatch, X-Ray)
#------------------------------------------------------------------------------
module "monitoring" {
  source = "../../modules/solution/monitoring"

  name_prefix      = local.name_prefix
  common_tags      = local.common_tags
  project_name     = var.solution.name
  environment      = local.environment
  kms_key_arn      = module.security.kms_key_arn
  alb_arn          = module.core.alb_arn
  asg_name         = module.core.asg_name
  rds_identifier   = module.database.rds_identifier
  cache_cluster_id = var.cache.enabled ? module.cache[0].cache_replication_group_id : ""
  monitoring       = var.monitoring
}

#------------------------------------------------------------------------------
# Best Practices (Config Rules, Budgets - reduced scope for test)
#------------------------------------------------------------------------------
module "best_practices" {
  source = "../../modules/solution/best-practices"

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }

  name_prefix        = local.name_prefix
  common_tags        = local.common_tags
  environment        = local.environment
  kms_key_arn        = module.security.kms_key_arn
  sns_topic_arn      = module.monitoring.sns_topic_arn
  config_rules       = var.config_rules
  guardduty_enhanced = var.guardduty_enhanced
  backup             = var.backup
  budget             = var.budget
}

#------------------------------------------------------------------------------
# Disaster Recovery (Disabled for test environment)
#------------------------------------------------------------------------------
module "dr" {
  source = "../../modules/solution/dr"
  count  = var.dr.enabled ? 1 : 0

  name_prefix   = local.name_prefix
  environment   = local.environment
  common_tags   = local.common_tags
  kms_key_arn   = module.security.kms_key_arn
  sns_topic_arn = module.monitoring.sns_topic_arn
  dr_region     = var.aws.dr_region
  dr            = var.dr
}

#===============================================================================
# INTEGRATIONS - Cross-module connections that break circular dependencies
#===============================================================================
#------------------------------------------------------------------------------
# WAF to ALB Association (connects security → core)
#------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "alb" {
  count = var.security.enable_waf && var.alb.enabled ? 1 : 0

  resource_arn = module.core.alb_arn
  web_acl_arn  = module.security.waf_web_acl_arn
}

#------------------------------------------------------------------------------
# Database CloudWatch Alarms (connects database → monitoring)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  count               = var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-db-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Database CPU utilization is high"
  dimensions          = { DBInstanceIdentifier = module.database.rds_identifier }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "db_storage" {
  count               = var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-db-storage-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB
  alarm_description   = "Database free storage space is low"
  dimensions          = { DBInstanceIdentifier = module.database.rds_identifier }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "db_connections" {
  count               = var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-db-connections-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "Database connection count is high"
  dimensions          = { DBInstanceIdentifier = module.database.rds_identifier }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}

#------------------------------------------------------------------------------
# Cache CloudWatch Alarms (connects cache → monitoring)
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cache_cpu" {
  count               = var.cache.enabled && var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-cache-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Cache CPU utilization is high"
  dimensions          = { CacheClusterId = module.cache[0].cache_replication_group_id }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cache_memory" {
  count               = var.cache.enabled && var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-cache-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Cache memory usage is high"
  dimensions          = { CacheClusterId = module.cache[0].cache_replication_group_id }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cache_evictions" {
  count               = var.cache.enabled && var.monitoring.enable_dashboard ? 1 : 0
  alarm_name          = "${local.name_prefix}-cache-evictions-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "Evictions"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Cache eviction rate is high"
  dimensions          = { CacheClusterId = module.cache[0].cache_replication_group_id }
  alarm_actions       = [module.monitoring.sns_topic_arn]
  tags                = local.common_tags
}
