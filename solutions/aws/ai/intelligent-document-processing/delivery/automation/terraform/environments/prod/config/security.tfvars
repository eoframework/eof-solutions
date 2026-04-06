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

