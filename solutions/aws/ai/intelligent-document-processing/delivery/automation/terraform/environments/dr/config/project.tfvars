#------------------------------------------------------------------------------
# Project Configuration - DR Environment
#------------------------------------------------------------------------------

project_name = "idp"  # Short name used in all resource names (e.g. idp-dr-*)
env          = "dr"   # Environment identifier - explicit, not inferred from path

aws = {
  region    = "us-west-2" # DR primary region (flipped from prod)
  dr_region = "us-east-1" # Points back to prod region
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
