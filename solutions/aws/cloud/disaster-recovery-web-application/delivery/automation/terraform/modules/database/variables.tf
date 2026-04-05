#------------------------------------------------------------------------------
# DR Web Application Database Module - Variables
#------------------------------------------------------------------------------

variable "project" {
  description = "Project configuration"
  type = object({
    name        = string
    environment = string
  })
}

variable "database" {
  description = "Database configuration"
  type = object({
    is_primary_region            = optional(bool, true)
    global_cluster_identifier    = optional(string, "")
    engine_version               = optional(string, "8.0.mysql_aurora.3.04.0")
    database_name                = optional(string, "app")
    master_username              = optional(string, "admin")
    master_password              = string
    instance_class               = optional(string, "db.r6g.large")
    instance_count               = optional(number, 2)
    backup_retention_days        = optional(number, 7)
    backup_window                = optional(string, "03:00-04:00")
    maintenance_window           = optional(string, "sun:04:00-sun:05:00")
    enable_deletion_protection   = optional(bool, true)
    skip_final_snapshot          = optional(bool, false)
    monitoring_interval          = optional(number, 60)
    enable_performance_insights  = optional(bool, true)
  })
}

variable "network" {
  description = "Network configuration"
  type = object({
    database_subnet_ids = list(string)
  })
}

variable "security" {
  description = "Security configuration"
  type = object({
    db_security_group_id = string
    kms_key_arn          = string
  })
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}
