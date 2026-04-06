#------------------------------------------------------------------------------
# Project Configuration - DR Environment
#------------------------------------------------------------------------------

project_name = "docintel"  # Short name used in all resource names (e.g. docintel-dr-*)
env          = "dr"        # Environment identifier — explicit, not inferred from path

azure_environment = "public"  # Azure cloud: "public" (commercial) or "usgovernment"

# Note: arm_subscription_id, arm_tenant_id, arm_client_id, arm_client_secret
# are defined in credentials.auto.tfvars (git-ignored, never commit)

azure = {
  region    = "westus2"  # DR primary region (flipped from prod)
  dr_region = "eastus"   # Points back to prod region
}

ownership = {
  cost_center  = "CC-AI-001"             # Cost center for billing allocation
  owner_email  = "ai-team@company.com"   # Technical owner contact
  project_code = "PRJ-DOCINTEL-2025"     # Project tracking code
}

solution = {
  name          = "Azure Document Intelligence" # Full name for tagging and catalog
  abbr          = "docintel"                    # Abbreviation for resource naming
  provider_name = "azure"                       # Cloud provider identifier
  category_name = "ai"                          # Solution category
}
