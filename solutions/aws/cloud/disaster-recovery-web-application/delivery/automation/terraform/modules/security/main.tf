#------------------------------------------------------------------------------
# DR Web Application - Security Module
#------------------------------------------------------------------------------
# Application security resources:
# - WAF Web ACL with managed rule groups and rate limiting
# - ALB security group (HTTP/HTTPS from internet)
# - Application security group (from ALB only)
# - Database security group (from app tier only)
#
# Note: KMS keys are created in the kms module to avoid circular dependency
# with the networking module (KMS needed for flow log encryption).
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# WAF Web ACL
#------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  count = var.security.enable_waf ? 1 : 0

  name        = "${var.project.name}-${var.project.environment}-waf"
  description = "WAF ACL for ${var.project.name} ${var.project.environment}"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project.name}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project.name}-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.security.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project.name}-waf"
    sampled_requests_enabled   = true
  }

  tags = var.common_tags
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.project.name}-${var.project.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.network.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet (redirect to HTTPS)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project.name}-${var.project.environment}-alb-sg"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.project.name}-${var.project.environment}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.network.vpc_id

  ingress {
    from_port       = var.network.app_port
    to_port         = var.network.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "Application traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project.name}-${var.project.environment}-app-sg"
  })
}

resource "aws_security_group" "db" {
  name        = "${var.project.name}-${var.project.environment}-db-sg"
  description = "Security group for Aurora database"
  vpc_id      = var.network.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "MySQL from application tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project.name}-${var.project.environment}-db-sg"
  })
}
