#------------------------------------------------------------------------------
# Security Configuration - PROD Environment
#------------------------------------------------------------------------------

auth = {
  advanced_security_mode     = "AUDIT"    # Advanced security mode
  auto_verified_attributes   = ["email"]  # Auto-verified attributes
  callback_urls              = []         # OAuth callback URLs
  domain                     = ""         # Cognito domain prefix
  enabled                    = true       # Enable Cognito authentication
  logout_urls                = []         # OAuth logout URLs
  mfa_configuration          = "OPTIONAL" # MFA configuration
  password_minimum_length    = 12         # Minimum password length
  password_require_lowercase = true       # Require lowercase
  password_require_numbers   = true       # Require numbers
  password_require_symbols   = true       # Require symbols
  password_require_uppercase = true       # Require uppercase
  username_attributes        = ["email"]  # Username attributes
}

security = {
  enable_kms_key_rotation  = true # Enable KMS key rotation
  kms_deletion_window_days = 30   # KMS key deletion window (days)
}

#------------------------------------------------------------------------------
# Security Groups
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
