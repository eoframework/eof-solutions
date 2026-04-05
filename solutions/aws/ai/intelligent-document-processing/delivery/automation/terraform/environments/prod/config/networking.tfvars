#------------------------------------------------------------------------------
# Networking Configuration - PROD Environment
#------------------------------------------------------------------------------
# VPC and subnet definitions for Lambda VPC mode.
# Only applied when application.lambda_vpc_enabled = true in application.tfvars.
#
# IP Range: 10.10.0.0/16 (PROD)
#   Reserved per RFC 1918. Chosen to avoid collision with common ranges:
#   - 10.0.0.0/16  (often used by default VPCs / dev environments)
#   - 10.100.0.0/16+ (reserved for future environments)
#
# Subnet naming convention: {solution}-{tier}-{availability-zone}
#------------------------------------------------------------------------------

vpc = {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_nat_gateway   = false  # Lambda reaches AWS services via VPC Gateway Endpoints (free)
  single_nat_gateway   = true   # Set true to use one NAT GW if enable_nat_gateway is turned on
}

subnets = {
  "idp-private-us-east-1a" = {
    cidr_block        = "10.10.1.0/24"  # 254 usable IPs
    availability_zone = "us-east-1a"
    layer             = "private"
  }
  "idp-private-us-east-1b" = {
    cidr_block        = "10.10.2.0/24"  # 254 usable IPs
    availability_zone = "us-east-1b"
    layer             = "private"
  }
}
