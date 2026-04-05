#------------------------------------------------------------------------------
# Cloud Migration Database Module
#------------------------------------------------------------------------------
# Provides RDS MySQL/PostgreSQL for migrated databases:
# - RDS Multi-AZ for production
# - DB subnet group
# - Parameter group
# - Enhanced monitoring
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

#------------------------------------------------------------------------------
# DB Subnet Group
#------------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Database subnet group for ${local.name_prefix}"
  subnet_ids  = var.network.database_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
  })
}

#------------------------------------------------------------------------------
# Parameter Group
#------------------------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-db-params"
  family      = "${var.database.engine}${regex("^[0-9]+\\.[0-9]+", var.database.engine_version)}"
  description = "RDS parameter group for ${local.name_prefix}"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# RDS Instance
#------------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-db"

  engine               = var.database.engine
  engine_version       = var.database.engine_version
  instance_class       = var.database.instance_class
  allocated_storage    = var.database.storage_size
  storage_type         = var.database.storage_type
  storage_encrypted    = true
  kms_key_id           = var.security.kms_key_arn

  db_name  = var.database.database_name
  username = var.database.master_username
  password = var.database.master_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = [var.security.db_security_group_id]

  multi_az             = var.database.multi_az
  publicly_accessible  = false
  deletion_protection  = var.database.enable_deletion_protection
  skip_final_snapshot  = var.database.skip_final_snapshot
  final_snapshot_identifier = var.database.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"

  backup_retention_period   = var.database.backup_retention_days
  backup_window             = var.database.backup_window
  maintenance_window        = var.database.maintenance_window

  # Enhanced Monitoring
  monitoring_interval = var.database.monitoring_interval
  monitoring_role_arn = var.database.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.database.enable_performance_insights
  performance_insights_kms_key_id       = var.database.enable_performance_insights ? var.security.kms_key_arn : null
  performance_insights_retention_period = var.database.enable_performance_insights ? 7 : null

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = var.database.engine == "mysql" ? ["audit", "error", "slowquery"] : ["postgresql"]

  copy_tags_to_snapshot = true

  tags = merge(var.common_tags, {
    Name   = "${local.name_prefix}-db"
    Backup = "true"
  })
}

#------------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  count = var.database.monitoring_interval > 0 ? 1 : 0

  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "monitoring.rds.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.database.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
