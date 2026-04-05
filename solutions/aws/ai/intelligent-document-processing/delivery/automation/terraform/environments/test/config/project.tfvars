#------------------------------------------------------------------------------
# Project Configuration - TEST Environment
#------------------------------------------------------------------------------

project_name = "idp"   # Short name used in all resource names (e.g. idp-test-*)
env          = "test"  # Environment identifier - explicit, not inferred from path

aws = {
  region    = "us-east-1" # Primary AWS region
  dr_region = "us-west-2" # DR region
  profile   = ""          # AWS CLI profile (optional)
}

ownership = {
  cost_center  = "CC-IDP-001"           # Cost center
  owner_email  = "idp-team@example.com" # Owner email
  project_code = "PRJ-IDP-2025"         # Project code
}

solution = {
  name          = "Intelligent Document Processing" # Display name (tags, catalog)
  abbr          = "idp"                             # Solution abbreviation
  provider_name = "aws"                             # Provider organisation name
  category_name = "ai"                              # Solution category
}
