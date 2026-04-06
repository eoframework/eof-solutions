#------------------------------------------------------------------------------
# Security Groups - TEST Environment
#------------------------------------------------------------------------------
# Manually maintained — not generated from configuration.csv.
# Complex map(object) structure cannot be expressed in flat CSV format.
#
# Only created when application.lambda_vpc_enabled = true.
#------------------------------------------------------------------------------

security_groups = {
  "idp-lambda" = {
    description = "IDP Lambda functions - HTTPS egress to AWS service endpoints only"

    egress_cidr = {
      "egress_tcp_443_all" = {
        from_port   = 443
        to_port     = 443
        ip_protocol = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "HTTPS to AWS service endpoints and VPC endpoints"
      }
    }
  }

  "idp-vpc-endpoints" = {
    description = "IDP VPC Interface Endpoints - accept HTTPS from Lambda functions only"

    ingress_sg = {
      "ingress_tcp_443_lambda" = {
        from_port                 = 443
        to_port                   = 443
        ip_protocol               = "tcp"
        source_security_group_key = "idp-lambda"
        description               = "HTTPS from IDP Lambda functions"
      }
    }
  }
}
