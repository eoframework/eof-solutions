#------------------------------------------------------------------------------
# Networking Configuration - TEST Environment
#------------------------------------------------------------------------------
# VPC and subnet definitions for Lambda VPC mode.
# Only applied when application.lambda_vpc_enabled = true in application.tfvars.
#
# IP Range: 10.20.0.0/16 (TEST)
#   Separated from PROD (10.10.0.0/16) to allow safe VPC peering in future.
#
# Subnet naming convention: {solution}-{tier}-{availability-zone}
#------------------------------------------------------------------------------

vpc = {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = false  # Lambda reaches AWS services via VPC Gateway Endpoints (free)
  single_nat_gateway   = true   # Cost-optimised: single NAT GW is sufficient for test
}

subnets = {
  "idp-private-us-east-1a" = {
    cidr_block        = "10.20.1.0/24"  # 254 usable IPs
    availability_zone = "us-east-1a"
    layer             = "private"
  }
  "idp-private-us-east-1b" = {
    cidr_block        = "10.20.2.0/24"  # 254 usable IPs
    availability_zone = "us-east-1b"
    layer             = "private"
  }
}
