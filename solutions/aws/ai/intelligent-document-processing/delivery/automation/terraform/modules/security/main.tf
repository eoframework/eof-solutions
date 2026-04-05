#------------------------------------------------------------------------------
# IDP Security Module
#------------------------------------------------------------------------------
# Provides core security infrastructure:
#   - KMS key for encryption at rest (S3, DynamoDB, CloudWatch, Lambda, etc.)
#   - Security groups from security_groups map (only when lambda_vpc_enabled = true)
#
# Security groups are created in two phases to support cross-SG rules without
# circular dependencies:
#   Phase 1 - aws_security_group:                  all SGs created (no inline rules)
#   Phase 2 - aws_vpc_security_group_ingress_rule  ingress rules (Provider 5+ resource)
#           - aws_vpc_security_group_egress_rule   egress rules  (Provider 5+ resource)
#
# The new rule resources (vs legacy aws_security_group_rule):
#   - ip_protocol instead of protocol
#   - cidr_ipv4 (single CIDR) instead of cidr_blocks (list)
#   - referenced_security_group_id instead of source_security_group_id
#   - Tags are supported per-rule
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"

  # Only create SGs when Lambda VPC mode is enabled and security_groups is populated
  create_sgs = var.lambda_vpc_enabled && var.vpc_id != null

  # Flatten ingress CIDR rules across all SGs into a single map
  # Key: "{sg_key}:{rule_key}" ensures uniqueness
  all_ingress_cidr = local.create_sgs ? {
    for pair in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_key, rule in sg.ingress_cidr : {
          id     = "${sg_key}:${rule_key}"
          sg_key = sg_key
          rule   = rule
        }
      ]
    ]) : pair.id => pair
  } : {}

  # Flatten egress CIDR rules across all SGs
  all_egress_cidr = local.create_sgs ? {
    for pair in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_key, rule in sg.egress_cidr : {
          id     = "${sg_key}:${rule_key}"
          sg_key = sg_key
          rule   = rule
        }
      ]
    ]) : pair.id => pair
  } : {}

  # Flatten ingress SG-reference rules across all SGs
  all_ingress_sg = local.create_sgs ? {
    for pair in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_key, rule in sg.ingress_sg : {
          id     = "${sg_key}:${rule_key}"
          sg_key = sg_key
          rule   = rule
        }
      ]
    ]) : pair.id => pair
  } : {}

  # Flatten egress SG-reference rules across all SGs
  all_egress_sg = local.create_sgs ? {
    for pair in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_key, rule in sg.egress_sg : {
          id     = "${sg_key}:${rule_key}"
          sg_key = sg_key
          rule   = rule
        }
      ]
    ]) : pair.id => pair
  } : {}
}

#------------------------------------------------------------------------------
# KMS Key for Encryption at Rest
#------------------------------------------------------------------------------
# Explicit key policy required — without it the key falls back to an implicit
# default that is harder to audit and audit tools flag as a finding.
#
# Policy grants:
#   - Root account: full kms:* access (required for IAM-delegated access to work)
#   - CloudWatch Logs service: encrypt/decrypt (cannot use IAM roles, needs key policy)
#   - All other services (Lambda, S3, DynamoDB, SNS, SQS, Step Functions):
#     access granted via IAM policies on their execution roles — root access above
#     enables this without listing every service here.
#------------------------------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = "${local.name_prefix} encryption key"
  deletion_window_in_days = var.security.kms_deletion_window_days
  enable_key_rotation     = var.security.enable_kms_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableIAMRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsEncryption"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}"
  target_key_id = aws_kms_key.main.key_id
}

#------------------------------------------------------------------------------
# Phase 1: Security Group shells (no inline rules)
#------------------------------------------------------------------------------
resource "aws_security_group" "this" {
  for_each = local.create_sgs ? var.security_groups : {}

  name        = "${local.name_prefix}-${each.key}"
  description = each.value.description
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}

#------------------------------------------------------------------------------
# Phase 2a: Ingress rules - CIDR sourced
# aws_vpc_security_group_ingress_rule (Provider 5+ — replaces aws_security_group_rule)
#------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "cidr" {
  for_each = local.all_ingress_cidr

  security_group_id = aws_security_group.this[each.value.sg_key].id
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  ip_protocol       = each.value.rule.ip_protocol
  cidr_ipv4         = each.value.rule.cidr_block
  description       = each.value.rule.description

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}

#------------------------------------------------------------------------------
# Phase 2b: Egress rules - CIDR sourced
#------------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "cidr" {
  for_each = local.all_egress_cidr

  security_group_id = aws_security_group.this[each.value.sg_key].id
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  ip_protocol       = each.value.rule.ip_protocol
  cidr_ipv4         = each.value.rule.cidr_block
  description       = each.value.rule.description

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}

#------------------------------------------------------------------------------
# Phase 2c: Ingress rules - SG sourced
#------------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "sg_ref" {
  for_each = local.all_ingress_sg

  security_group_id            = aws_security_group.this[each.value.sg_key].id
  from_port                    = each.value.rule.from_port
  to_port                      = each.value.rule.to_port
  ip_protocol                  = each.value.rule.ip_protocol
  referenced_security_group_id = aws_security_group.this[each.value.rule.source_security_group_key].id
  description                  = each.value.rule.description

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}

#------------------------------------------------------------------------------
# Phase 2d: Egress rules - SG sourced
#------------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "sg_ref" {
  for_each = local.all_egress_sg

  security_group_id            = aws_security_group.this[each.value.sg_key].id
  from_port                    = each.value.rule.from_port
  to_port                      = each.value.rule.to_port
  ip_protocol                  = each.value.rule.ip_protocol
  referenced_security_group_id = aws_security_group.this[each.value.rule.source_security_group_key].id
  description                  = each.value.rule.description

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
  })
}
