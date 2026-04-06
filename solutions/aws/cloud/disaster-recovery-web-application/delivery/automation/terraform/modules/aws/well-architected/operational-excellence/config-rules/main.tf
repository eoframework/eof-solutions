# AWS Config Rules Module
# Pillar: Operational Excellence
#
# Implements compliance monitoring and drift detection using AWS Config.
# Includes managed rules for common security and operational best practices.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  create_recorder = var.config_rules.create_recorder
  create_bucket   = local.create_recorder && var.config_bucket_name == ""
}

#------------------------------------------------------------------------------
# AWS Config Recorder & Delivery Channel
#------------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  count = local.create_recorder ? 1 : 0

  name     = "${var.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = var.config_rules.record_all_resources
    include_global_resource_types = var.config_rules.include_global_resources

    dynamic "exclusion_by_resource_types" {
      for_each = length(var.config_rules.excluded_resource_types) > 0 ? [1] : []
      content {
        resource_types = var.config_rules.excluded_resource_types
      }
    }
  }
}

resource "aws_config_delivery_channel" "main" {
  count = local.create_recorder ? 1 : 0

  name           = "${var.name_prefix}-config-delivery"
  s3_bucket_name = var.config_bucket_name != "" ? var.config_bucket_name : aws_s3_bucket.config[0].id
  s3_key_prefix  = var.config_rules.config_s3_prefix
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.config_rules.delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count = local.create_recorder ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

#------------------------------------------------------------------------------
# S3 Bucket for Config (if not provided)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = "${var.name_prefix}-config-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, {
    Name    = "${var.name_prefix}-config"
    Purpose = "AWSConfigDelivery"
  })
}

resource "aws_s3_bucket_versioning" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != "" ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : null
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  rule {
    id     = "expire-old-config-data"
    status = "Enabled"

    expiration {
      days = var.config_rules.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "config" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config[0].arn
        Condition = { StringEquals = { "AWS:SourceAccount" = data.aws_caller_identity.current.account_id } }
      },
      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# IAM Role for Config
#------------------------------------------------------------------------------

resource "aws_iam_role" "config" {
  count = local.create_recorder ? 1 : 0
  name  = "${var.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = local.create_recorder ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  count = local.create_recorder ? 1 : 0
  name  = "${var.name_prefix}-config-s3-policy"
  role  = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:PutObjectAcl"]
      Resource = var.config_bucket_name != "" ? "arn:aws:s3:::${var.config_bucket_name}/*" : "${aws_s3_bucket.config[0].arn}/*"
      Condition = { StringLike = { "s3:x-amz-acl" = "bucket-owner-full-control" } }
    }]
  })
}

#------------------------------------------------------------------------------
# AWS Managed Config Rules - Security
#------------------------------------------------------------------------------

resource "aws_config_config_rule" "encrypted_volumes" {
  count       = var.config_rules.enable_security_rules ? 1 : 0
  name        = "${var.name_prefix}-encrypted-volumes"
  description = "Checks if attached EBS volumes are encrypted"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  tags       = merge(var.common_tags, { Pillar = "Security", Rule = "encrypted-volumes" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "rds_encryption" {
  count       = var.config_rules.enable_security_rules ? 1 : 0
  name        = "${var.name_prefix}-rds-storage-encrypted"
  description = "Checks if RDS instances have storage encryption enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  tags       = merge(var.common_tags, { Pillar = "Security", Rule = "rds-storage-encrypted" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "s3_bucket_ssl" {
  count       = var.config_rules.enable_security_rules ? 1 : 0
  name        = "${var.name_prefix}-s3-bucket-ssl-requests-only"
  description = "Checks if S3 buckets require SSL for requests"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  tags       = merge(var.common_tags, { Pillar = "Security", Rule = "s3-bucket-ssl-requests-only" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "vpc_flow_logs" {
  count       = var.config_rules.enable_security_rules ? 1 : 0
  name        = "${var.name_prefix}-vpc-flow-logs-enabled"
  description = "Checks if VPC flow logs are enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  input_parameters = jsonencode({ trafficType = "ALL" })
  tags             = merge(var.common_tags, { Pillar = "Security", Rule = "vpc-flow-logs-enabled" })
  depends_on       = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "root_mfa" {
  count       = var.config_rules.enable_security_rules && var.config_rules.include_global_resources ? 1 : 0
  name        = "${var.name_prefix}-root-account-mfa-enabled"
  description = "Checks if root account has MFA enabled"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  tags       = merge(var.common_tags, { Pillar = "Security", Rule = "root-account-mfa-enabled" })
  depends_on = [aws_config_configuration_recorder.main]
}

#------------------------------------------------------------------------------
# AWS Managed Config Rules - Reliability
#------------------------------------------------------------------------------

resource "aws_config_config_rule" "rds_multi_az" {
  count       = var.config_rules.enable_reliability_rules ? 1 : 0
  name        = "${var.name_prefix}-rds-multi-az-support"
  description = "Checks if RDS instances have Multi-AZ enabled"

  source {
    owner             = "AWS"
    source_identifier = "RDS_MULTI_AZ_SUPPORT"
  }

  tags       = merge(var.common_tags, { Pillar = "Reliability", Rule = "rds-multi-az-support" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "elb_cross_zone" {
  count       = var.config_rules.enable_reliability_rules ? 1 : 0
  name        = "${var.name_prefix}-elb-cross-zone-enabled"
  description = "Checks if ELB has cross-zone load balancing enabled"

  source {
    owner             = "AWS"
    source_identifier = "ELB_CROSS_ZONE_LOAD_BALANCING_ENABLED"
  }

  tags       = merge(var.common_tags, { Pillar = "Reliability", Rule = "elb-cross-zone-enabled" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "db_backup" {
  count       = var.config_rules.enable_reliability_rules ? 1 : 0
  name        = "${var.name_prefix}-db-instance-backup-enabled"
  description = "Checks if RDS instances have automated backups enabled"

  source {
    owner             = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }

  input_parameters = jsonencode({ backupRetentionMinimum = var.config_rules.min_backup_retention_days })
  tags             = merge(var.common_tags, { Pillar = "Reliability", Rule = "db-instance-backup-enabled" })
  depends_on       = [aws_config_configuration_recorder.main]
}

#------------------------------------------------------------------------------
# AWS Managed Config Rules - Operational Excellence
#------------------------------------------------------------------------------

resource "aws_config_config_rule" "cloudwatch_alarm_action" {
  count       = var.config_rules.enable_operational_rules ? 1 : 0
  name        = "${var.name_prefix}-cloudwatch-alarm-action-check"
  description = "Checks if CloudWatch alarms have actions configured"

  source {
    owner             = "AWS"
    source_identifier = "CLOUDWATCH_ALARM_ACTION_CHECK"
  }

  tags       = merge(var.common_tags, { Pillar = "OperationalExcellence", Rule = "cloudwatch-alarm-action-check" })
  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  count       = var.config_rules.enable_operational_rules ? 1 : 0
  name        = "${var.name_prefix}-cloudtrail-enabled"
  description = "Checks if CloudTrail is enabled in the account"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  tags       = merge(var.common_tags, { Pillar = "OperationalExcellence", Rule = "cloudtrail-enabled" })
  depends_on = [aws_config_configuration_recorder.main]
}

#------------------------------------------------------------------------------
# AWS Managed Config Rules - Cost Optimization
#------------------------------------------------------------------------------

resource "aws_config_config_rule" "ebs_optimized" {
  count       = var.config_rules.enable_cost_rules ? 1 : 0
  name        = "${var.name_prefix}-ebs-optimized-instance"
  description = "Checks if EBS optimization is enabled for supported instances"

  source {
    owner             = "AWS"
    source_identifier = "EBS_OPTIMIZED_INSTANCE"
  }

  tags       = merge(var.common_tags, { Pillar = "CostOptimization", Rule = "ebs-optimized-instance" })
  depends_on = [aws_config_configuration_recorder.main]
}
