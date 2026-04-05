#------------------------------------------------------------------------------
# Networking Configuration - DR Environment
#------------------------------------------------------------------------------
# VPC and subnet definitions for Lambda VPC mode.
# Only applied when application.lambda_vpc_enabled = true in application.tfvars.
#
# IP Range: 10.30.0.0/16 (DR - us-west-2)
#   Separated from PROD (10.10.0.0/16) and TEST (10.20.0.0/16).
#   Non-overlapping ranges enable future cross-region VPC peering or Transit Gateway.
#
# Subnet naming convention: {solution}-{tier}-{availability-zone}
# Note: DR region is us-west-2 - AZ names reflect the DR region.
#------------------------------------------------------------------------------

vpc = {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = false  # Lambda reaches AWS services via VPC Gateway Endpoints (free)
  single_nat_gateway   = true   # Single NAT GW is sufficient for DR standby environment
}

subnets = {
  "idp-private-us-west-2a" = {
    cidr_block        = "10.30.1.0/24"  # 254 usable IPs
    availability_zone = "us-west-2a"
    layer             = "private"
  }
  "idp-private-us-west-2b" = {
    cidr_block        = "10.30.2.0/24"  # 254 usable IPs
    availability_zone = "us-west-2b"
    layer             = "private"
  }
}
