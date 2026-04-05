#------------------------------------------------------------------------------
# Application Configuration - PROD Environment
#------------------------------------------------------------------------------
# Generated from configuration on 2025-12-02 00:00:41
#
# To regenerate: python generate-tfvars.py /path/to/solution
#------------------------------------------------------------------------------

api = {
  allowed_content_types  = ["application/pdf", "image/png", "image/jpeg", "image/tiff"] # Allowed content types
  default_page_size      = 20                                                           # Default pagination size
  enable_cors            = true                                                         # Enable CORS
  endpoint_type          = "REGIONAL"                                                   # API endpoint type
  max_file_size_mb       = 50                                                           # Max upload size (MB)
  stage_name             = "v1"                                                         # API Gateway stage
  throttling_burst_limit = 1000                                                         # API burst limit
  throttling_rate_limit  = 500                                                          # API steady-state rate
  version                = "1.0.0"                                                      # API version
}

application = {
  lambda_runtime     = "python3.12" # Lambda runtime
  lambda_vpc_enabled = false        # Enable Lambda VPC mode
}

comprehend = {
  enable_entity_detection = true    # Enable entity detection
  enable_key_phrases      = true    # Enable key phrase extraction
  enable_pii_detection    = true    # Enable PII detection
  enable_sentiment        = false   # Enable sentiment analysis
  language_code           = "en"    # Default language code
  pii_entity_types        = ["ALL"] # PII entity types to detect
}

human_review = {
  confidence_threshold      = 80                                                       # Confidence threshold
  custom_ui_template        = ""                                                       # Custom UI template
  enabled                   = true                                                     # Enable A2I human review
  task_availability_seconds = 43200                                                    # Task availability (seconds)
  task_count                = 1                                                        # Workers per task
  task_description          = "Review the extracted document data and verify accuracy" # Task description
  task_price_usd            = "0.05"                                                   # Task price (USD)
  task_title                = "Document Review Task"                                   # Task title
  use_private_workforce     = true                                                     # Use private workforce
  workteam_arn              = ""                                                       # SageMaker workteam ARN
}

textract = {
  confidence_threshold     = 80                                    # Minimum confidence for auto-processing
  enable_expense           = false                                 # Enable expense analysis
  enable_forms             = true                                  # Enable form extraction
  enable_id                = false                                 # Enable ID analysis
  enable_queries           = false                                 # Enable queries feature
  enable_signatures        = false                                 # Enable signature detection
  enable_tables            = true                                  # Enable table extraction
  max_file_size_mb         = 50                                    # Maximum file size (MB)
  max_polling_attempts     = 20                                    # Max polling attempts
  polling_interval_seconds = 30                                    # Async polling interval
  supported_document_types = ["pdf", "png", "jpg", "jpeg", "tiff"] # Supported document types
}
