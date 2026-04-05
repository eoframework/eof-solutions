#------------------------------------------------------------------------------
# IDP DR Module - Outputs
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# DR Vault Outputs (DR Region)
#------------------------------------------------------------------------------

output "vault" {
  description = "DR vault resources in DR region"
  value = local.vault_enabled ? {
    enabled          = true
    region           = data.aws_region.dr.id
    kms_key_arn      = aws_kms_key.dr[0].arn
    kms_key_id       = aws_kms_key.dr[0].key_id
    bucket_arn       = aws_s3_bucket.dr_documents[0].arn
    bucket_id        = aws_s3_bucket.dr_documents[0].id
    backup_vault_arn = aws_backup_vault.dr[0].arn
    backup_vault_name = aws_backup_vault.dr[0].name
    vault_lock_enabled = var.dr.vault_enable_lock
    restore_role_arn = aws_iam_role.dr_restore[0].arn
    notifications_topic_arn = aws_sns_topic.dr_notifications[0].arn
  } : { enabled = false }
}

#------------------------------------------------------------------------------
# DR Replication Outputs (Source Region)
#------------------------------------------------------------------------------

output "replication" {
  description = "DR replication resources in source region"
  value = local.replication_enabled ? {
    enabled                    = true
    s3_replication_role_arn    = aws_iam_role.s3_replication[0].arn
    dynamodb_replication_role_arn = aws_iam_role.dynamodb_replication[0].arn
    source_vault_arn           = aws_backup_vault.source[0].arn
    source_vault_name          = aws_backup_vault.source[0].name
    backup_plan_id             = aws_backup_plan.dynamodb[0].id
    backup_plan_arn            = aws_backup_plan.dynamodb[0].arn
    backup_role_arn            = aws_iam_role.backup[0].arn
    local_retention_days       = var.dr.backup_local_retention_days
    dr_retention_days          = var.dr.backup_retention_days
    weekly_enabled             = var.dr.enable_weekly_backup
  } : { enabled = false }
}

#------------------------------------------------------------------------------
# Status Summary
#------------------------------------------------------------------------------

output "enabled" {
  description = "Whether DR is enabled (vault and/or replication)"
  value = {
    vault       = local.vault_enabled
    replication = local.replication_enabled
  }
}

output "summary" {
  description = "DR configuration summary"
  value = {
    vault_enabled       = local.vault_enabled
    replication_enabled = local.replication_enabled
    dr_region           = local.vault_enabled ? data.aws_region.dr.id : null
    dr_bucket           = local.vault_enabled ? aws_s3_bucket.dr_documents[0].id : null
    dr_vault            = local.vault_enabled ? aws_backup_vault.dr[0].name : null
    source_vault        = local.replication_enabled ? aws_backup_vault.source[0].name : null
    replication_types   = local.replication_enabled ? {
      s3       = "Cross-Region Replication (CRR)"
      dynamodb = "AWS Backup with Cross-Region Copy"
    } : null
  }
}
