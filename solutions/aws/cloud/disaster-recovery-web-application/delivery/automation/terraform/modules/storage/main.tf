#------------------------------------------------------------------------------
# DR Web Application Storage Module
#------------------------------------------------------------------------------
# Provides S3 storage with cross-region replication for DR:
# - Primary S3 bucket for application data
# - S3 versioning for recovery
# - Cross-region replication to DR region
# - Lifecycle policies for cost optimization
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#------------------------------------------------------------------------------
# Primary S3 Bucket
#------------------------------------------------------------------------------
resource "aws_s3_bucket" "main" {
  bucket = "${local.name_prefix}-data-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, {
    Name   = "${local.name_prefix}-data"
    Backup = "true"
  })
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.storage.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.security.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# Lifecycle Configuration
#------------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = var.storage.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.storage.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.storage.noncurrent_version_expiration_days
    }
  }
}

#------------------------------------------------------------------------------
# Cross-Region Replication (if enabled)
#------------------------------------------------------------------------------
resource "aws_iam_role" "replication" {
  count = var.storage.enable_replication ? 1 : 0

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

resource "aws_iam_role_policy" "replication" {
  count = var.storage.enable_replication ? 1 : 0

  name = "${local.name_prefix}-s3-replication-policy"
  role = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SourceBucketAccess"
        Effect   = "Allow"
        Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Sid    = "SourceObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Sid    = "DestinationBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${var.storage.dr_bucket_arn}/*"
      },
      {
        Sid      = "SourceKMSDecrypt"
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = var.security.kms_key_arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      },
      {
        Sid      = "DestinationKMSEncrypt"
        Effect   = "Allow"
        Action   = ["kms:Encrypt"]
        Resource = var.storage.dr_kms_key_arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.storage.dr_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "main" {
  count = var.storage.enable_replication ? 1 : 0

  bucket = aws_s3_bucket.main.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = var.storage.dr_bucket_arn
      storage_class = var.storage.replication_storage_class

      encryption_configuration {
        replica_kms_key_id = var.storage.dr_kms_key_arn
      }

      dynamic "replication_time" {
        for_each = var.storage.enable_replication_time_control ? [1] : []
        content {
          status = "Enabled"
          time {
            minutes = 15
          }
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

#------------------------------------------------------------------------------
# CloudWatch Alarms for Replication
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  count = var.storage.enable_replication ? 1 : 0

  alarm_name          = "${local.name_prefix}-s3-replication-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.storage.replication_latency_threshold
  alarm_description   = "S3 replication latency exceeded threshold"
  alarm_actions       = var.monitoring.sns_topic_arn != "" ? [var.monitoring.sns_topic_arn] : []

  dimensions = {
    SourceBucket      = aws_s3_bucket.main.id
    DestinationBucket = element(split(":", var.storage.dr_bucket_arn), length(split(":", var.storage.dr_bucket_arn)) - 1)
    RuleId            = "replicate-all"
  }

  tags = var.common_tags
}
