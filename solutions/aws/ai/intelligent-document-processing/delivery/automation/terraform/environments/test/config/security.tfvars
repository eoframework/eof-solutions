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

