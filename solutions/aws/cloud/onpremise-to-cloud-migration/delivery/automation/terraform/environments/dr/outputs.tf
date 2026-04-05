#------------------------------------------------------------------------------
# Cloud Migration - DR Environment Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name (standby)"
  value       = module.compute.alb_dns_name
}

output "vpn_gateway_id" {
  description = "ID of the VPN Gateway for hybrid connectivity"
  value       = module.networking.vpn_gateway_id
}

output "db_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = module.database.db_endpoint
}

output "s3_bucket_id" {
  description = "S3 bucket ID (replication destination)"
  value       = module.storage.bucket_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = module.kms.key_arn
}

output "dr_status" {
  description = "DR environment status"
  value = {
    region         = var.aws.region
    primary_region = var.aws.dr_region
    standby_mode   = true
    asg_capacity   = var.compute.asg_desired_capacity
  }
}
