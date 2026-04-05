#------------------------------------------------------------------------------
# IDP Storage Module
#------------------------------------------------------------------------------
# Creates S3 buckets and DynamoDB tables for IDP document storage
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

#------------------------------------------------------------------------------
# Documents S3 Bucket
#------------------------------------------------------------------------------
module "documents_bucket" {
  source = "../aws/s3"

  bucket_name  = "${local.name_prefix}-documents-${var.aws_account_id}"
  force_destroy = var.storage.force_destroy

  versioning_enabled = var.storage.versioning_enabled

  kms_key_arn = var.kms_key_arn

  # Block all public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle rules for document storage optimization
  lifecycle_rules = [
    {
      id                                 = "documents-lifecycle"
      enabled                            = true
      prefix                             = "uploads/"
      transition_ia_days                 = var.storage.transition_to_ia_days
      transition_glacier_days            = var.storage.transition_to_glacier_days
      expiration_days                    = var.storage.document_expiration_days
      noncurrent_version_expiration_days = var.storage.noncurrent_version_expiration_days
    },
    {
      id                                 = "results-lifecycle"
      enabled                            = true
      prefix                             = "results/"
      transition_ia_days                 = var.storage.transition_to_ia_days
      noncurrent_version_expiration_days = var.storage.noncurrent_version_expiration_days
    },
    {
      id      = "temp-cleanup"
      enabled = true
      prefix  = "temp/"
      expiration_days = 1
    }
  ]

  # CORS for direct upload support
  cors_rules = var.storage.enable_direct_upload ? [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST"]
      allowed_origins = var.storage.cors_allowed_origins
      expose_headers  = ["ETag", "x-amz-meta-*"]
      max_age_seconds = 3600
    }
  ] : []

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Results DynamoDB Table
#------------------------------------------------------------------------------
module "results_table" {
  source = "../aws/dynamodb"

  table_name   = "${local.name_prefix}-results"
  billing_mode = var.database.billing_mode

  # Provisioned capacity (only used if billing_mode is PROVISIONED)
  read_capacity  = var.database.read_capacity
  write_capacity = var.database.write_capacity

  # Primary key
  hash_key  = "documentId"
  range_key = "createdAt"

  attributes = [
    {
      name = "documentId"
      type = "S"
    },
    {
      name = "createdAt"
      type = "S"
    },
    {
      name = "userId"
      type = "S"
    },
    {
      name = "status"
      type = "S"
    },
    {
      name = "documentType"
      type = "S"
    }
  ]

  # Global Secondary Indexes for common query patterns
  global_secondary_indexes = [
    {
      name            = "userId-createdAt-index"
      hash_key        = "userId"
      range_key       = "createdAt"
      projection_type = "ALL"
      read_capacity   = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_read_capacity : null
      write_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_write_capacity : null
    },
    {
      name            = "status-createdAt-index"
      hash_key        = "status"
      range_key       = "createdAt"
      projection_type = "INCLUDE"
      non_key_attributes = ["documentId", "userId", "documentType"]
      read_capacity   = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_read_capacity : null
      write_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_write_capacity : null
    },
    {
      name            = "documentType-createdAt-index"
      hash_key        = "documentType"
      range_key       = "createdAt"
      projection_type = "KEYS_ONLY"
      read_capacity   = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_read_capacity : null
      write_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_write_capacity : null
    }
  ]

  # TTL for automatic cleanup
  ttl_attribute = var.database.ttl_enabled ? "expiresAt" : null

  # Point-in-time recovery
  point_in_time_recovery_enabled = var.database.point_in_time_recovery

  # Encryption
  kms_key_arn = var.kms_key_arn

  # Stream for change events
  stream_enabled   = var.database.stream_enabled
  stream_view_type = var.database.stream_view_type

  # Auto-scaling (only for PROVISIONED mode)
  enable_autoscaling              = var.database.billing_mode == "PROVISIONED" ? var.database.enable_autoscaling : false
  autoscaling_read_max_capacity   = var.database.autoscaling_max_read
  autoscaling_write_max_capacity  = var.database.autoscaling_max_write
  autoscaling_target_utilization  = var.database.autoscaling_target_utilization

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Processing Jobs DynamoDB Table
#------------------------------------------------------------------------------
module "jobs_table" {
  source = "../aws/dynamodb"

  table_name   = "${local.name_prefix}-processing-jobs"
  billing_mode = var.database.billing_mode

  read_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.read_capacity : null
  write_capacity = var.database.billing_mode == "PROVISIONED" ? var.database.write_capacity : null

  hash_key  = "jobId"
  range_key = "documentId"

  attributes = [
    {
      name = "jobId"
      type = "S"
    },
    {
      name = "documentId"
      type = "S"
    },
    {
      name = "jobStatus"
      type = "S"
    },
    {
      name = "startedAt"
      type = "S"
    }
  ]

  global_secondary_indexes = [
    {
      name            = "documentId-index"
      hash_key        = "documentId"
      projection_type = "ALL"
      read_capacity   = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_read_capacity : null
      write_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_write_capacity : null
    },
    {
      name            = "jobStatus-startedAt-index"
      hash_key        = "jobStatus"
      range_key       = "startedAt"
      projection_type = "INCLUDE"
      non_key_attributes = ["documentId", "jobId"]
      read_capacity   = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_read_capacity : null
      write_capacity  = var.database.billing_mode == "PROVISIONED" ? var.database.gsi_write_capacity : null
    }
  ]

  ttl_attribute = "expiresAt"

  point_in_time_recovery_enabled = var.database.point_in_time_recovery

  kms_key_arn = var.kms_key_arn

  common_tags = var.common_tags
}

#------------------------------------------------------------------------------
# Output Bucket (for processed results export)
#------------------------------------------------------------------------------
module "output_bucket" {
  count  = var.storage.create_output_bucket ? 1 : 0
  source = "../aws/s3"

  bucket_name   = "${local.name_prefix}-output-${var.aws_account_id}"
  force_destroy = var.storage.force_destroy

  versioning_enabled = false

  kms_key_arn = var.kms_key_arn

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  lifecycle_rules = [
    {
      id              = "output-cleanup"
      enabled         = true
      expiration_days = var.storage.output_expiration_days
    }
  ]

  common_tags = var.common_tags
}
