# Generic AWS VPC Module
# Creates VPC with public, private, and database subnets
# Includes Internet Gateway, NAT Gateway(s), and VPC Flow Logs

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_count = min(length(var.network.public_subnet_cidrs), length(data.aws_availability_zones.available.names))
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------

resource "aws_vpc" "this" {
  cidr_block           = var.network.vpc_cidr
  enable_dns_hostnames = var.network.enable_dns_hostnames
  enable_dns_support   = var.network.enable_dns_support

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# Public Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.network.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.network.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

#------------------------------------------------------------------------------
# Private Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(var.network.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.network.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-${count.index + 1}"
    Tier = "private"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route_table" "private" {
  count = var.network.single_nat_gateway ? 1 : length(var.network.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route" "private_nat" {
  count = var.network.enable_nat_gateway ? (var.network.single_nat_gateway ? 1 : length(var.network.private_subnet_cidrs)) : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[var.network.single_nat_gateway ? 0 : count.index].id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.network.single_nat_gateway ? 0 : count.index % length(aws_route_table.private)].id
}

#------------------------------------------------------------------------------
# Database Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "database" {
  count = length(var.network.database_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.network.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-${count.index + 1}"
    Tier = "database"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private[var.network.single_nat_gateway ? 0 : count.index % length(aws_route_table.private)].id
}

resource "aws_db_subnet_group" "this" {
  count = length(var.network.database_subnet_cidrs) > 0 ? 1 : 0

  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_elasticache_subnet_group" "this" {
  count = length(var.network.private_subnet_cidrs) > 0 ? 1 : 0

  name       = "${var.name_prefix}-cache-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-cache-subnet-group"
  })

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# NAT Gateway
#------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  count  = var.network.enable_nat_gateway ? (var.network.single_nat_gateway ? 1 : local.az_count) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_nat_gateway" "this" {
  count = var.network.enable_nat_gateway ? (var.network.single_nat_gateway ? 1 : local.az_count) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]

  lifecycle {
    ignore_changes = [tags_all]
  }
}

#------------------------------------------------------------------------------
# VPC Flow Logs
#------------------------------------------------------------------------------

resource "aws_flow_log" "this" {
  count = var.network.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn             = aws_iam_role.flow_logs[0].arn
  max_aggregation_interval = 60

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.network.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name_prefix}/flow-logs"
  retention_in_days = var.network.flow_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = var.tags

  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.network.enable_flow_logs ? 1 : 0

  name = "${var.name_prefix}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.network.enable_flow_logs ? 1 : 0

  name = "${var.name_prefix}-flow-logs-policy"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}
