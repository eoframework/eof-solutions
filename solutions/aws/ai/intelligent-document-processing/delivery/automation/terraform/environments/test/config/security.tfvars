#------------------------------------------------------------------------------
# Security Configuration - TEST Environment
#------------------------------------------------------------------------------

auth = {
  advanced_security_mode     = "OFF"     # Relaxed for test environment
  auto_verified_attributes   = ["email"]
  callback_urls              = []
  domain                     = ""
  enabled                    = true
  logout_urls                = []
  mfa_configuration          = "OFF"     # MFA off in test for ease of use
  password_minimum_length    = 8         # Relaxed for test
  password_require_lowercase = true
  password_require_numbers   = true
  password_require_symbols   = false     # Relaxed for test
  password_require_uppercase = true
  username_attributes        = ["email"]
}

security = {
  enable_kms_key_rotation  = true
  kms_deletion_window_days = 7   # Shorter window for test (faster cleanup)
}

#------------------------------------------------------------------------------
# Security Groups
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
