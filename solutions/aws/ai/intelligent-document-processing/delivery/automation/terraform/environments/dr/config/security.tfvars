#------------------------------------------------------------------------------
# Security Configuration - DR Environment
#------------------------------------------------------------------------------

auth = {
  advanced_security_mode     = "AUDIT"
  auto_verified_attributes   = ["email"]
  callback_urls              = []
  domain                     = ""
  enabled                    = true
  logout_urls                = []
  mfa_configuration          = "OPTIONAL"
  password_minimum_length    = 12
  password_require_lowercase = true
  password_require_numbers   = true
  password_require_symbols   = true
  password_require_uppercase = true
  username_attributes        = ["email"]
}

security = {
  enable_kms_key_rotation  = true
  kms_deletion_window_days = 30
}

