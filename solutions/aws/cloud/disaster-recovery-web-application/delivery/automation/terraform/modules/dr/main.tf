#------------------------------------------------------------------------------
# DR Web Application - Disaster Recovery Module
#------------------------------------------------------------------------------
# Provides Route 53 failover and DR automation:
# - Route 53 health checks and failover routing
# - DR region S3 bucket (replication destination)
# - DR region KMS key
# - AWS Backup with cross-region copy
# - Lambda failover automation (optional)
#------------------------------------------------------------------------------

locals {
  name_prefix   = "${var.project.name}-${var.project.environment}"
  vault_enabled = var.dr.vault_enabled
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_region" "dr" {
  provider = aws.dr
}

#==============================================================================
# ROUTE 53 FAILOVER (Primary Region)
#==============================================================================

#------------------------------------------------------------------------------
# Route 53 Health Check
#------------------------------------------------------------------------------
resource "aws_route53_health_check" "primary" {
  count = var.dns.hosted_zone_id != "" ? 1 : 0

  fqdn              = var.primary.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = var.dns.health_check_path
  failure_threshold = var.dns.health_check_failure_threshold
  request_interval  = var.dns.health_check_interval

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-primary-health-check"
  })
}

#------------------------------------------------------------------------------
# Route 53 Failover Records
#------------------------------------------------------------------------------
resource "aws_route53_record" "primary" {
  count = var.dns.hosted_zone_id != "" ? 1 : 0

  zone_id = var.dns.hosted_zone_id
  name    = var.dns.domain_name
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary[0].id

  alias {
    name                   = var.primary.alb_dns_name
    zone_id                = var.primary.alb_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "secondary" {
  count = var.dns.hosted_zone_id != "" && var.dr.enabled ? 1 : 0

  zone_id = var.dns.hosted_zone_id
  name    = var.dns.domain_name
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier = "secondary"

  alias {
    name                   = var.dr_alb.dns_name
    zone_id                = var.dr_alb.zone_id
    evaluate_target_health = true
  }
}

#==============================================================================
# DR VAULT (DR Region Resources)
#==============================================================================

#------------------------------------------------------------------------------
# DR KMS Key
#------------------------------------------------------------------------------
resource "aws_kms_key" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  description             = "${local.name_prefix} DR encryption key"
  deletion_window_in_days = var.dr.kms_deletion_window_days
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3Replication"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowBackupService"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, { Purpose = "DR-Encryption" })
}

resource "aws_kms_alias" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name          = "alias/${local.name_prefix}-dr"
  target_key_id = aws_kms_key.dr[0].key_id
}

#------------------------------------------------------------------------------
# DR S3 Bucket (Replication Destination)
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = "${local.name_prefix}-data-dr-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, {
    Name    = "${local.name_prefix}-data-dr"
    Purpose = "DR-Replication-Destination"
  })
}

resource "aws_s3_bucket_versioning" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dr[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr[0].id

  rule {
    id     = "dr-lifecycle"
    status = "Enabled"

    transition {
      days          = var.dr.vault_transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.dr.vault_noncurrent_version_expiration_days
    }
  }
}

#------------------------------------------------------------------------------
# DR Backup Vault
#------------------------------------------------------------------------------
resource "aws_backup_vault" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name        = "${local.name_prefix}-dr-vault"
  kms_key_arn = aws_kms_key.dr[0].arn

  tags = merge(var.common_tags, { Purpose = "DR-Destination" })
}

#==============================================================================
# AWS BACKUP (Primary Region)
#==============================================================================

#------------------------------------------------------------------------------
# Backup Vault
#------------------------------------------------------------------------------
resource "aws_backup_vault" "primary" {
  count = var.dr.replication_enabled ? 1 : 0

  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = var.security.kms_key_arn

  tags = merge(var.common_tags, { Purpose = "DR-Source" })
}

#------------------------------------------------------------------------------
# Backup IAM Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "backup" {
  count = var.dr.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  count = var.dr.replication_enabled ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count = var.dr.replication_enabled ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy" "backup_kms" {
  count = var.dr.replication_enabled && local.vault_enabled ? 1 : 0

  name = "${local.name_prefix}-backup-kms"
  role = aws_iam_role.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "KMSAccess"
      Effect = "Allow"
      Action = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ]
      Resource = [var.security.kms_key_arn, aws_kms_key.dr[0].arn]
    }]
  })
}

#------------------------------------------------------------------------------
# Backup Plan
#------------------------------------------------------------------------------
resource "aws_backup_plan" "main" {
  count = var.dr.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-backup-plan"

  # Daily backup with cross-region copy
  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.primary[0].name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = var.dr.backup_retention_days
    }

    dynamic "copy_action" {
      for_each = local.vault_enabled ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.dr[0].arn

        lifecycle {
          delete_after = var.dr.dr_backup_retention_days
        }
      }
    }

    enable_continuous_backup = var.dr.enable_continuous_backup
  }

  # Weekly backup
  dynamic "rule" {
    for_each = var.dr.enable_weekly_backup ? [1] : []
    content {
      rule_name         = "weekly-backup"
      target_vault_name = aws_backup_vault.primary[0].name
      schedule          = "cron(0 5 ? * SUN *)"

      lifecycle {
        delete_after = var.dr.weekly_backup_retention_days
      }

      dynamic "copy_action" {
        for_each = local.vault_enabled ? [1] : []
        content {
          destination_vault_arn = aws_backup_vault.dr[0].arn

          lifecycle {
            delete_after = var.dr.weekly_backup_retention_days
          }
        }
      }
    }
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Backup Selection (by tag)
#------------------------------------------------------------------------------
resource "aws_backup_selection" "main" {
  count = var.dr.replication_enabled ? 1 : 0

  name         = "${local.name_prefix}-backup-selection"
  plan_id      = aws_backup_plan.main[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}

#------------------------------------------------------------------------------
# Backup Notifications
#------------------------------------------------------------------------------
resource "aws_backup_vault_notifications" "primary" {
  count = var.dr.replication_enabled && var.monitoring.sns_topic_arn != "" ? 1 : 0

  backup_vault_name   = aws_backup_vault.primary[0].name
  sns_topic_arn       = var.monitoring.sns_topic_arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "BACKUP_JOB_FAILED",
    "COPY_JOB_STARTED",
    "COPY_JOB_SUCCESSFUL",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RESTORE_JOB_FAILED"
  ]
}

#==============================================================================
# DR MONITORING
#==============================================================================

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "health_check" {
  count = var.dns.hosted_zone_id != "" ? 1 : 0

  alarm_name          = "${local.name_prefix}-health-check-status"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  alarm_description   = "Primary region health check failed"
  alarm_actions       = var.monitoring.sns_topic_arn != "" ? [var.monitoring.sns_topic_arn] : []

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_replication_lag" {
  count = var.dr.enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-aurora-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "AuroraGlobalDBReplicationLag"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = var.dr.replication_lag_threshold_ms
  alarm_description   = "Aurora Global Database replication lag exceeded threshold"
  alarm_actions       = var.monitoring.sns_topic_arn != "" ? [var.monitoring.sns_topic_arn] : []

  dimensions = {
    DBClusterIdentifier = var.primary.aurora_cluster_id
  }

  tags = var.common_tags
}
