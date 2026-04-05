#------------------------------------------------------------------------------
# IDP Networking Module - Outputs
#------------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "private_subnet_ids" {
  description = "Map of private subnet IDs keyed by subnet name"
  value       = { for key, subnet in aws_subnet.private : key => subnet.id }
}

output "private_subnet_ids_list" {
  description = "List of private subnet IDs (for Lambda VPC config)"
  value       = [for subnet in aws_subnet.private : subnet.id]
}

output "private_subnet_azs" {
  description = "Map of availability zones keyed by subnet name"
  value       = { for key, subnet in aws_subnet.private : key => subnet.availability_zone }
}

output "public_subnet_ids" {
  description = "Map of public subnet IDs keyed by AZ (empty when NAT Gateway disabled)"
  value       = { for key, subnet in aws_subnet.public : key => subnet.id }
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs keyed by AZ (empty when NAT Gateway disabled)"
  value       = { for key, ngw in aws_nat_gateway.main : key => ngw.id }
}

output "private_route_table_ids" {
  description = "Map of private route table IDs keyed by subnet name"
  value       = { for key, rt in aws_route_table.private : key => rt.id }
}

output "s3_endpoint_id" {
  description = "VPC Gateway Endpoint ID for S3"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "VPC Gateway Endpoint ID for DynamoDB"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "flow_log_id" {
  description = "VPC Flow Log ID (null when flow logs disabled)"
  value       = var.vpc.enable_flow_logs ? aws_flow_log.main[0].id : null
}

output "flow_log_group_name" {
  description = "CloudWatch log group name for VPC flow logs (null when disabled)"
  value       = var.vpc.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : null
}
