#------------------------------------------------------------------------------
# Cloud Migration - Compute Module
#------------------------------------------------------------------------------
# Application compute infrastructure:
# - Application Load Balancer (internet-facing)
# - ALB target group and listeners (HTTP/HTTPS)
# - EC2 Launch Template with IMDSv2 and EBS encryption
# - Optional data volume for migrated application data
# - Auto Scaling Group with rolling refresh
# - Scale up/down policies
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
# Application Load Balancer
#------------------------------------------------------------------------------
resource "aws_lb" "this" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security.alb_security_group_id]
  subnets            = var.network.public_subnet_ids

  enable_deletion_protection = var.compute.enable_deletion_protection

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "this" {
  name     = "${local.name_prefix}-tg"
  port     = var.compute.app_port
  protocol = "HTTP"
  vpc_id   = var.network.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = var.compute.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-tg"
  })
}

resource "aws_lb_listener" "https" {
  count = var.compute.ssl_certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.compute.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.compute.ssl_certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.compute.ssl_certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.compute.ssl_certificate_arn == "" ? aws_lb_target_group.this.arn : null
  }
}

#------------------------------------------------------------------------------
# Launch Template
#------------------------------------------------------------------------------
resource "aws_launch_template" "this" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = var.compute.ami_id != "" ? var.compute.ami_id : data.aws_ami.amazon_linux_2.id
  instance_type = var.compute.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security.app_security_group_id]
  }

  iam_instance_profile {
    arn = var.compute.instance_profile_arn
  }

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # OS root volume
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.compute.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.security.kms_key_arn
      delete_on_termination = true
    }
  }

  # Data volume for migrated application data
  dynamic "block_device_mappings" {
    for_each = var.compute.data_volume_size > 0 ? [1] : []
    content {
      device_name = "/dev/xvdb"

      ebs {
        volume_size           = var.compute.data_volume_size
        volume_type           = "gp3"
        encrypted             = true
        kms_key_id            = var.security.kms_key_arn
        delete_on_termination = false
      }
    }
  }

  user_data = var.compute.user_data_base64

  tag_specifications {
    resource_type = "instance"

    tags = merge(var.common_tags, {
      Name   = "${local.name_prefix}-app"
      Backup = "true"
    })
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(var.common_tags, {
      Name = "${local.name_prefix}-app-volume"
    })
  }

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# Auto Scaling Group
#------------------------------------------------------------------------------
resource "aws_autoscaling_group" "this" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.network.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.this.arn]
  health_check_type   = "ELB"

  min_size         = var.compute.asg_min_size
  max_size         = var.compute.asg_max_size
  desired_capacity = var.compute.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(var.common_tags, {
      Name = "${local.name_prefix}-app"
    })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${local.name_prefix}-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${local.name_prefix}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.this.name
}
