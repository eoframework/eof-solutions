# AWS GuardDuty Module
# Pillar: Security
#
# Implements intelligent threat detection using GuardDuty.
# Monitors for malicious activity and unauthorized behavior.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  create_bucket = var.guardduty.enable_s3_export && var.findings_bucket_arn == ""
}

#------------------------------------------------------------------------------
# GuardDuty Detector
#------------------------------------------------------------------------------

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = var.guardduty.finding_publishing_frequency

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-guardduty", Pillar = "Security" })
}

#------------------------------------------------------------------------------
# GuardDuty Detector Features (replaces deprecated datasources block)
#------------------------------------------------------------------------------

resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = var.guardduty.enable_s3_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "eks_audit_logs" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EKS_AUDIT_LOGS"
  status      = var.guardduty.enable_eks_protection ? "ENABLED" : "DISABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = var.guardduty.enable_malware_protection ? "ENABLED" : "DISABLED"
}

#------------------------------------------------------------------------------
# GuardDuty Publishing Destination (S3)
#------------------------------------------------------------------------------

resource "aws_guardduty_publishing_destination" "s3" {
  count           = var.guardduty.enable_s3_export ? 1 : 0
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = var.findings_bucket_arn != "" ? var.findings_bucket_arn : aws_s3_bucket.findings[0].arn
  kms_key_arn     = var.kms_key_arn

  depends_on = [aws_s3_bucket_policy.findings]
}

#------------------------------------------------------------------------------
# S3 Bucket for Findings (if not provided)
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = "${var.name_prefix}-guardduty-findings-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.common_tags, { Name = "${var.name_prefix}-guardduty-findings", Purpose = "GuardDutyFindings" })
}

resource "aws_s3_bucket_versioning" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.findings[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.findings[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.findings[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.findings[0].id

  rule {
    id     = "expire-old-findings"
    status = "Enabled"
    expiration {
      days = var.guardduty.findings_retention_days
    }
  }
}

resource "aws_s3_bucket_policy" "findings" {
  count  = local.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.findings[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowGuardDutyGetBucketLocation"
        Effect    = "Allow"
        Principal = { Service = "guardduty.amazonaws.com" }
        Action    = "s3:GetBucketLocation"
        Resource  = aws_s3_bucket.findings[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = "arn:aws:guardduty:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:detector/${aws_guardduty_detector.main.id}"
          }
        }
      },
      {
        Sid       = "AllowGuardDutyPutObject"
        Effect    = "Allow"
        Principal = { Service = "guardduty.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.findings[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = "arn:aws:guardduty:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:detector/${aws_guardduty_detector.main.id}"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedUploads"
        Effect    = "Deny"
        Principal = { Service = "guardduty.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.findings[0].arn}/*"
        Condition = { StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" } }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# EventBridge Rule for High Severity Findings
#------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "high_severity" {
  count       = var.guardduty.enable_alerts ? 1 : 0
  name        = "${var.name_prefix}-guardduty-high-severity"
  description = "Capture high severity GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", var.guardduty.alert_severity_threshold] }]
    }
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "sns" {
  count     = var.guardduty.enable_alerts && var.sns_topic_arn != "" ? 1 : 0
  rule      = aws_cloudwatch_event_rule.high_severity[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      severity    = "$.detail.severity"
      type        = "$.detail.type"
      description = "$.detail.description"
      region      = "$.region"
      account     = "$.account"
    }
    input_template = <<EOF
{
  "source": "GuardDuty",
  "severity": <severity>,
  "type": "<type>",
  "description": "<description>",
  "region": "<region>",
  "account": "<account>"
}
EOF
  }
}

#------------------------------------------------------------------------------
# IP Set for Trusted IPs (Optional)
#------------------------------------------------------------------------------

resource "aws_guardduty_ipset" "trusted" {
  count       = var.guardduty.trusted_ip_list_key != "" ? 1 : 0
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${var.guardduty.trusted_ip_list_bucket}/${var.guardduty.trusted_ip_list_key}"
  name        = "${var.name_prefix}-trusted-ips"
  tags        = var.common_tags
}

#------------------------------------------------------------------------------
# Threat Intel Set (Optional)
#------------------------------------------------------------------------------

resource "aws_guardduty_threatintelset" "custom" {
  count       = var.guardduty.threat_intel_list_key != "" ? 1 : 0
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${var.guardduty.threat_intel_list_bucket}/${var.guardduty.threat_intel_list_key}"
  name        = "${var.name_prefix}-threat-intel"
  tags        = var.common_tags
}
