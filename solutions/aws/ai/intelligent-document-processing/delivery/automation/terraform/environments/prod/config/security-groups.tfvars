#------------------------------------------------------------------------------
# Security Groups - PROD Environment
#------------------------------------------------------------------------------
# Manually maintained — not generated from configuration.csv.
# Complex map(object) structure cannot be expressed in flat CSV format.
#
# Only created when application.lambda_vpc_enabled = true.
#
# IDP requires two security groups:
#   idp-lambda        - Applied to all Lambda functions in the VPC.
#                       Outbound HTTPS only; no inbound rules (Lambda is
#                       triggered by AWS services, never by inbound TCP).
#   idp-vpc-endpoints - Applied to VPC Interface Endpoints (SQS, Step
#                       Functions, Textract, Comprehend, etc.).
#                       Accepts HTTPS only from the Lambda SG.
#
# Rule key convention: {direction}_{protocol}_{port}_{source/dest}
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
