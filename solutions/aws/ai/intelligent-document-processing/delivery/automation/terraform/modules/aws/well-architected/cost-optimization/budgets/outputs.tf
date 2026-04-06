# AWS Budgets Module - Outputs

output "monthly_budget_name" {
  description = "Monthly cost budget name"
  value       = var.budget.enable_cost_budget ? aws_budgets_budget.monthly_cost[0].name : null
}

output "monthly_budget_id" {
  description = "Monthly cost budget ID"
  value       = var.budget.enable_cost_budget ? aws_budgets_budget.monthly_cost[0].id : null
}

output "ec2_budget_name" {
  description = "EC2 cost budget name"
  value       = var.budget.enable_service_budgets && var.budget.ec2_budget_amount > 0 ? aws_budgets_budget.ec2[0].name : null
}

output "rds_budget_name" {
  description = "RDS cost budget name"
  value       = var.budget.enable_service_budgets && var.budget.rds_budget_amount > 0 ? aws_budgets_budget.rds[0].name : null
}

output "budget_action_role_arn" {
  description = "IAM role ARN for budget actions"
  value       = var.budget.enable_actions ? aws_iam_role.budget_action[0].arn : null
}
