#------------------------------------------------------------------------------
# IDP DR Module
#------------------------------------------------------------------------------
# Consolidated disaster recovery module combining:
# - DR Vault (runs in DR region via aws.dr provider)
# - DR Replication (runs in source region via default aws provider)
#
# Architecture:
# - Vault creates destination resources in DR region (S3 bucket, Backup vault, KMS)
# - Replication configures source region to replicate to DR (S3 CRR, Backup plans)
#------------------------------------------------------------------------------

locals {
  name_prefix       = "${var.project.name}-${var.project.environment}"
  vault_enabled     = var.dr.vault_enabled
  replication_enabled = var.dr.replication_enabled && local.vault_enabled
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
# PART 1: DR VAULT (Runs in DR Region)
#==============================================================================

#------------------------------------------------------------------------------
# KMS Key for DR Region Encryption
#------------------------------------------------------------------------------
resource "aws_kms_key" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  description             = "${local.name_prefix} DR encryption key"
  deletion_window_in_days = var.dr.vault_kms_deletion_window_days
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
resource "aws_s3_bucket" "dr_documents" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = "${local.name_prefix}-documents-dr-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, {
    Name    = "${local.name_prefix}-documents-dr"
    Purpose = "DR-Replication-Destination"
  })
}

resource "aws_s3_bucket_versioning" "dr_documents" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr_documents[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_documents" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr_documents[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dr[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "dr_documents" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr_documents[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "dr_documents" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  bucket = aws_s3_bucket.dr_documents[0].id

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

resource "aws_backup_vault_lock_configuration" "dr" {
  count    = local.vault_enabled && var.dr.vault_enable_lock ? 1 : 0
  provider = aws.dr

  backup_vault_name = aws_backup_vault.dr[0].name
}

#------------------------------------------------------------------------------
# DR Restore Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "dr_restore" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name = "${local.name_prefix}-dr-restore-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "dr_restore" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  role       = aws_iam_role.dr_restore[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy" "dr_restore_dynamodb" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name = "${local.name_prefix}-dr-restore-dynamodb"
  role = aws_iam_role.dr_restore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBRestore"
        Effect = "Allow"
        Action = [
          "dynamodb:RestoreTableFromBackup",
          "dynamodb:RestoreTableToPointInTime",
          "dynamodb:CreateTable",
          "dynamodb:DescribeTable",
          "dynamodb:UpdateTable",
          "dynamodb:UpdateContinuousBackups",
          "dynamodb:TagResource"
        ]
        Resource = "*"
      },
      {
        Sid      = "KMSAccess"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant"]
        Resource = aws_kms_key.dr[0].arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "dr_restore_s3" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name = "${local.name_prefix}-dr-restore-s3"
  role = aws_iam_role.dr_restore[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "S3Access"
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:GetBucketLocation"]
      Resource = [aws_s3_bucket.dr_documents[0].arn, "${aws_s3_bucket.dr_documents[0].arn}/*"]
    }]
  })
}

#------------------------------------------------------------------------------
# DR SNS Topic
#------------------------------------------------------------------------------
resource "aws_sns_topic" "dr_notifications" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  name              = "${local.name_prefix}-dr-notifications"
  kms_master_key_id = aws_kms_key.dr[0].id

  tags = var.common_tags
}

resource "aws_backup_vault_notifications" "dr" {
  count    = local.vault_enabled ? 1 : 0
  provider = aws.dr

  backup_vault_name   = aws_backup_vault.dr[0].name
  sns_topic_arn       = aws_sns_topic.dr_notifications[0].arn
  backup_vault_events = [
    "COPY_JOB_STARTED", "COPY_JOB_SUCCESSFUL", "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED", "RESTORE_JOB_COMPLETED", "RESTORE_JOB_FAILED"
  ]
}

#==============================================================================
# PART 2: DR REPLICATION (Runs in Source Region)
#==============================================================================

#------------------------------------------------------------------------------
# S3 Cross-Region Replication
#------------------------------------------------------------------------------
resource "aws_iam_role" "s3_replication" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "s3_replication" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-s3-replication-policy"
  role = aws_iam_role.s3_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SourceBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = var.storage.documents_bucket_arn
      },
      {
        Sid      = "SourceObjectAccess"
        Effect   = "Allow"
        Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = "${var.storage.documents_bucket_arn}/*"
      },
      {
        Sid      = "DestinationBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = "${aws_s3_bucket.dr_documents[0].arn}/*"
      },
      {
        Sid      = "SourceKMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.kms_key_arn
        Condition = {
          StringLike = {
            "kms:ViaService"               = "s3.${data.aws_region.current.id}.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = "${var.storage.documents_bucket_arn}/*"
          }
        }
      },
      {
        Sid      = "DestinationKMSEncrypt"
        Effect   = "Allow"
        Action   = ["kms:Encrypt"]
        Resource = aws_kms_key.dr[0].arn
        Condition = {
          StringLike = {
            "kms:ViaService"               = "s3.${data.aws_region.dr.id}.amazonaws.com"
            "kms:EncryptionContext:aws:s3:arn" = "${aws_s3_bucket.dr_documents[0].arn}/*"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "documents" {
  count = local.replication_enabled ? 1 : 0

  bucket = var.storage.documents_bucket_id
  role   = aws_iam_role.s3_replication[0].arn

  rule {
    id     = "replicate-all-documents"
    status = "Enabled"

    filter { prefix = "" }

    delete_marker_replication { status = "Enabled" }

    destination {
      bucket        = aws_s3_bucket.dr_documents[0].arn
      storage_class = var.dr.storage_replication_class

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.dr[0].arn
      }

      dynamic "replication_time" {
        for_each = var.dr.enable_replication_time_control ? [1] : []
        content {
          status = "Enabled"
          time { minutes = 15 }
        }
      }

      metrics {
        status = "Enabled"
        event_threshold { minutes = 15 }
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects { status = "Enabled" }
    }
  }
}

#------------------------------------------------------------------------------
# DynamoDB Replication Role
#------------------------------------------------------------------------------
resource "aws_iam_role" "dynamodb_replication" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-dynamodb-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "dynamodb.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "dynamodb_replication" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-dynamodb-replication-policy"
  role = aws_iam_role.dynamodb_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBReplication"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem",
          "dynamodb:BatchWriteItem", "dynamodb:DescribeTable", "dynamodb:DescribeStream",
          "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          var.storage.results_table_arn, "${var.storage.results_table_arn}/stream/*",
          var.storage.jobs_table_arn, "${var.storage.jobs_table_arn}/stream/*"
        ]
      },
      {
        Sid      = "KMSAccess"
        Effect   = "Allow"
        Action   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
        Resource = [var.kms_key_arn, aws_kms_key.dr[0].arn]
      }
    ]
  })
}

#------------------------------------------------------------------------------
# AWS Backup (Source Region)
#------------------------------------------------------------------------------
resource "aws_backup_vault" "source" {
  count = local.replication_enabled ? 1 : 0

  name        = "${local.name_prefix}-backup-vault"
  kms_key_arn = var.kms_key_arn

  tags = merge(var.common_tags, { Purpose = "DR-Source" })
}

resource "aws_iam_role" "backup" {
  count = local.replication_enabled ? 1 : 0

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
  count = local.replication_enabled ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  count = local.replication_enabled ? 1 : 0

  role       = aws_iam_role.backup[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_iam_role_policy" "backup_kms" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-backup-kms"
  role = aws_iam_role.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "KMSAccess"
      Effect   = "Allow"
      Action   = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey", "kms:CreateGrant"]
      Resource = [var.kms_key_arn, aws_kms_key.dr[0].arn]
    }]
  })
}

resource "aws_backup_plan" "dynamodb" {
  count = local.replication_enabled ? 1 : 0

  name = "${local.name_prefix}-dynamodb-backup-plan"

  rule {
    rule_name         = "daily-dynamodb-backup"
    target_vault_name = aws_backup_vault.source[0].name
    schedule          = "cron(0 5 * * ? *)"

    lifecycle {
      delete_after = var.dr.backup_local_retention_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr[0].arn

      lifecycle {
        delete_after = var.dr.backup_retention_days
      }
    }

    enable_continuous_backup = true
  }

  dynamic "rule" {
    for_each = var.dr.enable_weekly_backup ? [1] : []
    content {
      rule_name         = "weekly-dynamodb-backup"
      target_vault_name = aws_backup_vault.source[0].name
      schedule          = "cron(0 5 ? * SUN *)"

      lifecycle {
        delete_after = var.dr.weekly_backup_retention_days
      }

      copy_action {
        destination_vault_arn = aws_backup_vault.dr[0].arn

        lifecycle {
          delete_after = var.dr.weekly_backup_retention_days
        }
      }
    }
  }

  tags = var.common_tags
}

resource "aws_backup_selection" "dynamodb" {
  count = local.replication_enabled ? 1 : 0

  name         = "${local.name_prefix}-dynamodb-selection"
  plan_id      = aws_backup_plan.dynamodb[0].id
  iam_role_arn = aws_iam_role.backup[0].arn

  resources = [
    var.storage.results_table_arn,
    var.storage.jobs_table_arn
  ]
}

resource "aws_backup_vault_notifications" "source" {
  count = local.replication_enabled && var.sns_topic_arn != null ? 1 : 0

  backup_vault_name   = aws_backup_vault.source[0].name
  sns_topic_arn       = var.sns_topic_arn
  backup_vault_events = [
    "BACKUP_JOB_STARTED", "BACKUP_JOB_COMPLETED", "BACKUP_JOB_FAILED",
    "COPY_JOB_STARTED", "COPY_JOB_SUCCESSFUL", "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED", "RESTORE_JOB_COMPLETED", "RESTORE_JOB_FAILED"
  ]
}

#------------------------------------------------------------------------------
# Replication Monitoring Alarms
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "s3_replication_latency" {
  count = local.replication_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-s3-replication-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Maximum"
  threshold           = 900
  alarm_description   = "S3 replication latency exceeded threshold"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    SourceBucket      = var.storage.documents_bucket_id
    DestinationBucket = aws_s3_bucket.dr_documents[0].id
    RuleId            = "replicate-all-documents"
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "s3_replication_pending" {
  count = local.replication_enabled ? 1 : 0

  alarm_name          = "${local.name_prefix}-s3-replication-pending"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BytesPendingReplication"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Average"
  threshold           = 104857600
  alarm_description   = "S3 pending replication bytes exceeded threshold"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    SourceBucket      = var.storage.documents_bucket_id
    DestinationBucket = aws_s3_bucket.dr_documents[0].id
    RuleId            = "replicate-all-documents"
  }

  tags = var.common_tags
}
