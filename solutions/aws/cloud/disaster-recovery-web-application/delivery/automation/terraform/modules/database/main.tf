#------------------------------------------------------------------------------
# DR Web Application Database Module
#------------------------------------------------------------------------------
# Provides Aurora Global Database for cross-region disaster recovery:
# - Aurora MySQL cluster (primary or secondary)
# - DB subnet group
# - Cluster parameter group
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
# Cluster Parameter Group
#------------------------------------------------------------------------------
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${local.name_prefix}-aurora-cluster-params"
  family      = "aurora-mysql8.0"
  description = "Aurora cluster parameter group for ${local.name_prefix}"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# DB Parameter Group
#------------------------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${local.name_prefix}-aurora-db-params"
  family      = "aurora-mysql8.0"
  description = "Aurora DB parameter group for ${local.name_prefix}"

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
# Aurora Global Cluster (Primary Region Only)
#------------------------------------------------------------------------------
resource "aws_rds_global_cluster" "main" {
  count = var.database.is_primary_region ? 1 : 0

  global_cluster_identifier = "${var.project.name}-global"
  engine                    = "aurora-mysql"
  engine_version            = var.database.engine_version
  database_name             = var.database.database_name
  storage_encrypted         = true
}

#------------------------------------------------------------------------------
# Aurora Cluster
#------------------------------------------------------------------------------
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${local.name_prefix}-aurora-cluster"

  # Global cluster association
  global_cluster_identifier = var.database.is_primary_region ? aws_rds_global_cluster.main[0].id : var.database.global_cluster_identifier

  engine         = "aurora-mysql"
  engine_version = var.database.engine_version
  engine_mode    = "provisioned"

  # Only set for primary region
  database_name   = var.database.is_primary_region ? var.database.database_name : null
  master_username = var.database.is_primary_region ? var.database.master_username : null
  master_password = var.database.is_primary_region ? var.database.master_password : null

  db_subnet_group_name            = aws_db_subnet_group.main.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [var.security.db_security_group_id]

  # Encryption
  storage_encrypted = true
  kms_key_id        = var.security.kms_key_arn

  # Backup (only for primary)
  backup_retention_period   = var.database.is_primary_region ? var.database.backup_retention_days : 1
  preferred_backup_window   = var.database.backup_window
  preferred_maintenance_window = var.database.maintenance_window

  # Deletion protection
  deletion_protection = var.database.enable_deletion_protection
  skip_final_snapshot = var.database.skip_final_snapshot
  final_snapshot_identifier = var.database.skip_final_snapshot ? null : "${local.name_prefix}-final-snapshot"

  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = ["audit", "error", "slowquery"]

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-aurora-cluster"
  })

  lifecycle {
    ignore_changes = [
      replication_source_identifier,
      global_cluster_identifier
    ]
  }
}

#------------------------------------------------------------------------------
# Aurora Instances
#------------------------------------------------------------------------------
resource "aws_rds_cluster_instance" "main" {
  count = var.database.instance_count

  identifier         = "${local.name_prefix}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id

  engine         = aws_rds_cluster.main.engine
  engine_version = aws_rds_cluster.main.engine_version
  instance_class = var.database.instance_class

  db_subnet_group_name    = aws_db_subnet_group.main.name
  db_parameter_group_name = aws_db_parameter_group.main.name

  # Enhanced monitoring
  monitoring_interval = var.database.monitoring_interval
  monitoring_role_arn = var.database.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled          = var.database.enable_performance_insights
  performance_insights_kms_key_id       = var.database.enable_performance_insights ? var.security.kms_key_arn : null
  performance_insights_retention_period = var.database.enable_performance_insights ? 7 : null

  publicly_accessible  = false
  copy_tags_to_snapshot = true

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-aurora-${count.index + 1}"
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
