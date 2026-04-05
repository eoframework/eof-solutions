#------------------------------------------------------------------------------
# DR Web Application Database Module - Outputs
#------------------------------------------------------------------------------

output "cluster_id" {
  description = "ID of the Aurora cluster"
  value       = aws_rds_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the Aurora cluster"
  value       = aws_rds_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint of the Aurora cluster"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "Port of the Aurora cluster"
  value       = aws_rds_cluster.main.port
}

output "global_cluster_id" {
  description = "ID of the Aurora Global Cluster (primary region only)"
  value       = var.database.is_primary_region ? aws_rds_global_cluster.main[0].id : null
}

output "global_cluster_arn" {
  description = "ARN of the Aurora Global Cluster (primary region only)"
  value       = var.database.is_primary_region ? aws_rds_global_cluster.main[0].arn : null
}

output "instance_ids" {
  description = "IDs of the Aurora instances"
  value       = aws_rds_cluster_instance.main[*].id
}

output "instance_endpoints" {
  description = "Endpoints of the Aurora instances"
  value       = aws_rds_cluster_instance.main[*].endpoint
}
