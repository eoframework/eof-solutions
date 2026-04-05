#------------------------------------------------------------------------------
# IDP Networking Module
#------------------------------------------------------------------------------
# Creates self-contained network infrastructure for the IDP solution:
#   - VPC with DNS support
#   - Private subnets (one per AZ, defined via subnets map)
#   - Public subnets + IGW + NAT Gateway (optional - only when enable_nat_gateway)
#   - Route tables with correct associations
#   - VPC Gateway Endpoints: S3 and DynamoDB (always - free, keeps traffic private)
#
# All Lambda functions run in private subnets. Traffic to AWS services is routed
# through Gateway Endpoints (free) rather than NAT Gateway wherever possible.
# Enable NAT Gateway only when Lambda functions need to reach the public internet.
#------------------------------------------------------------------------------

locals {
  name_prefix = "${var.project.name}-${var.project.environment}"

  # Separate private and public subnets from the flat subnets map
  private_subnets = {
    for key, subnet in var.subnets : key => subnet
    if subnet.layer == "private"
  }

  # Collect unique AZs from private subnets for NAT gateway placement
  private_azs = distinct([for s in values(local.private_subnets) : s.availability_zone])
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_support   = var.vpc.enable_dns_support
  enable_dns_hostnames = var.vpc.enable_dns_hostnames

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# Private Subnets
#------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-${each.key}"
    Tier = "Private"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# Internet Gateway + Public Subnets (only when NAT Gateway is enabled)
#------------------------------------------------------------------------------
resource "aws_internet_gateway" "main" {
  count = var.vpc.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-igw"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# One public subnet per private AZ to house the NAT Gateway(s)
resource "aws_subnet" "public" {
  for_each = var.vpc.enable_nat_gateway ? {
    for az in local.private_azs : az => {
      # Derive a non-overlapping CIDR by offsetting into the second /20 block
      # Private subnets use the lower half; public subnets use the upper half
      cidr_block        = cidrsubnet(var.vpc.cidr_block, 4, index(local.private_azs, az) + 8)
      availability_zone = az
    }
  } : {}

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-public-${each.key}"
    Tier = "Public"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# NAT Gateway (optional)
#------------------------------------------------------------------------------
# single_nat_gateway = true  → one NAT GW in the first AZ (cost-optimised for non-prod)
# single_nat_gateway = false → one NAT GW per AZ (HA for production)
#------------------------------------------------------------------------------
locals {
  nat_azs = var.vpc.enable_nat_gateway ? (
    var.vpc.single_nat_gateway ? [local.private_azs[0]] : local.private_azs
  ) : []
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_azs)

  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_nat_gateway" "main" {
  for_each = toset(local.nat_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------------------

# Public route table (only when NAT is enabled - needed for IGW route)
resource "aws_route_table" "public" {
  count = var.vpc.enable_nat_gateway ? 1 : 0

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route_table_association" "public" {
  for_each = var.vpc.enable_nat_gateway ? aws_subnet.public : {}

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

# Private route tables - one per AZ when multi-NAT, one shared when single-NAT or no NAT
resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.vpc.enable_nat_gateway ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      nat_gateway_id = var.vpc.single_nat_gateway ? (
        aws_nat_gateway.main[local.private_azs[0]].id
      ) : (
        aws_nat_gateway.main[each.value.availability_zone].id
      )
    }
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-private-rt-${each.key}"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

#------------------------------------------------------------------------------
# VPC Gateway Endpoints - S3 and DynamoDB
#------------------------------------------------------------------------------
# Gateway endpoints are free and keep traffic within the AWS network.
# Always created when a VPC exists - no reason not to have them.
#------------------------------------------------------------------------------

data "aws_region" "current" {}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private)[*].id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-s3-endpoint"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = values(aws_route_table.private)[*].id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-dynamodb-endpoint"
  })
}

#------------------------------------------------------------------------------
# VPC Flow Logs (optional)
#------------------------------------------------------------------------------
# Captures IP traffic metadata for security auditing and connectivity debugging.
# Writes to CloudWatch Logs. Enable with vpc.enable_flow_logs = true.
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.vpc.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/flow-logs/${local.name_prefix}"
  retention_in_days = var.vpc.flow_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.vpc.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.vpc.enable_flow_logs ? 1 : 0

  name = "${local.name_prefix}-vpc-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "main" {
  count = var.vpc.enable_flow_logs ? 1 : 0

  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-flow-logs"
  })

  depends_on = [aws_iam_role_policy.flow_logs]
}
