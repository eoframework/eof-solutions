#------------------------------------------------------------------------------
# DR Web Application Monitoring Module
#------------------------------------------------------------------------------
# Provides comprehensive monitoring for disaster recovery:
# - CloudWatch dashboard for DR operations
# - CloudWatch alarms for RTO/RPO tracking
# - SNS topic for notifications
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

#------------------------------------------------------------------------------
# SNS Topic for Alerts
#------------------------------------------------------------------------------
resource "aws_sns_topic" "alerts" {
  name              = "${local.name_prefix}-dr-alerts"
  kms_master_key_id = var.security.kms_key_id

  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count = var.monitoring.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.monitoring.alert_email
}

#------------------------------------------------------------------------------
# CloudWatch Dashboard
#------------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dr-operations"

  dashboard_body = jsonencode({
    widgets = [
      # Header
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project.name} - Disaster Recovery Dashboard"
        }
      },
      # Route 53 Health Check
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "Primary Health Check Status"
          region = var.aws.region
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", "HealthCheckId", var.resources.health_check_id]
          ]
          stat   = "Minimum"
          period = 60
          yAxis = {
            left = { min = 0, max = 1 }
          }
        }
      },
      # ALB Request Count
      {
        type   = "metric"
        x      = 8
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.aws.region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.resources.alb_arn_suffix, { stat = "Sum" }]
          ]
          period = 60
        }
      },
      # ALB Target Response Time
      {
        type   = "metric"
        x      = 16
        y      = 1
        width  = 8
        height = 6
        properties = {
          title  = "ALB Target Response Time"
          region = var.aws.region
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.resources.alb_arn_suffix, { stat = "Average" }],
            ["...", { stat = "p99" }]
          ]
          period = 60
        }
      },
      # Aurora Replication Lag
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Aurora Global DB Replication Lag (ms)"
          region = var.aws.region
          metrics = [
            ["AWS/RDS", "AuroraGlobalDBReplicationLag", "DBClusterIdentifier", var.resources.aurora_cluster_id]
          ]
          stat   = "Average"
          period = 60
          annotations = {
            horizontal = [
              { value = var.monitoring.rpo_target_ms, label = "RPO Target" }
            ]
          }
        }
      },
      # S3 Replication Latency
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "S3 Replication Latency (seconds)"
          region = var.aws.region
          metrics = [
            ["AWS/S3", "ReplicationLatency", "SourceBucket", var.resources.s3_bucket_id, "DestinationBucket", var.resources.s3_dr_bucket_id, "RuleId", "replicate-all"]
          ]
          stat   = "Maximum"
          period = 300
        }
      },
      # ASG Capacity
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "Auto Scaling Group Capacity"
          region = var.aws.region
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.resources.asg_name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupMinSize", ".", "."],
            [".", "GroupMaxSize", ".", "."]
          ]
          stat   = "Average"
          period = 60
        }
      },
      # EC2 CPU Utilization
      {
        type   = "metric"
        x      = 8
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "EC2 CPU Utilization"
          region = var.aws.region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.resources.asg_name, { stat = "Average" }],
            ["...", { stat = "Maximum" }]
          ]
          period = 60
        }
      },
      # Aurora CPU Utilization
      {
        type   = "metric"
        x      = 16
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "Aurora CPU Utilization"
          region = var.aws.region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.resources.aurora_cluster_id, { stat = "Average" }]
          ]
          period = 60
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# CloudWatch Alarms
#------------------------------------------------------------------------------
# ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = var.monitoring.alb_5xx_threshold
  alarm_description   = "ALB 5xx error rate exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.resources.alb_arn_suffix
  }

  tags = var.common_tags
}

# ALB Response Time
resource "aws_cloudwatch_metric_alarm" "alb_latency" {
  alarm_name          = "${local.name_prefix}-alb-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  extended_statistic  = "p99"
  threshold           = var.monitoring.alb_latency_threshold
  alarm_description   = "ALB p99 latency exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.resources.alb_arn_suffix
  }

  tags = var.common_tags
}

# ASG Unhealthy Hosts
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Unhealthy targets detected in target group"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = var.resources.alb_arn_suffix
    TargetGroup  = var.resources.target_group_arn_suffix
  }

  tags = var.common_tags
}

# Aurora CPU High
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  alarm_name          = "${local.name_prefix}-aurora-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.aurora_cpu_threshold
  alarm_description   = "Aurora CPU utilization exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.resources.aurora_cluster_id
  }

  tags = var.common_tags
}

# Aurora Connections
resource "aws_cloudwatch_metric_alarm" "aurora_connections" {
  alarm_name          = "${local.name_prefix}-aurora-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.monitoring.aurora_connections_threshold
  alarm_description   = "Aurora database connections exceeded threshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.resources.aurora_cluster_id
  }

  tags = var.common_tags
}
