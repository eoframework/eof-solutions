#------------------------------------------------------------------------------
# DR Web Application - Security Module Outputs
#------------------------------------------------------------------------------

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (null if WAF disabled)"
  value       = var.security.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}
