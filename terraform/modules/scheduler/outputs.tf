output "lambda_function_name" {
  description = "Name of the resource scheduler Lambda function"
  value       = aws_lambda_function.scheduler.function_name
}

output "lambda_function_arn" {
  description = "ARN of the resource scheduler Lambda function"
  value       = aws_lambda_function.scheduler.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_role.arn
}

output "stop_eventbridge_rule_name" {
  description = "Name of the EventBridge rule for stopping resources"
  value       = aws_cloudwatch_event_rule.stop_schedule.name
}

output "start_eventbridge_rule_name" {
  description = "Name of the EventBridge rule for starting resources"
  value       = aws_cloudwatch_event_rule.start_schedule.name
}

output "weekend_stop_eventbridge_rule_name" {
  description = "Name of the EventBridge rule for weekend stopping"
  value       = aws_cloudwatch_event_rule.weekend_stop_schedule.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Lambda function"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "nodegroup_config_table_name" {
  description = "Name of the DynamoDB table for nodegroup configurations (if enabled)"
  value       = var.enable_nodegroup_config_table ? aws_dynamodb_table.nodegroup_configs[0].name : null
}

output "nodegroup_config_table_arn" {
  description = "ARN of the DynamoDB table for nodegroup configurations (if enabled)"
  value       = var.enable_nodegroup_config_table ? aws_dynamodb_table.nodegroup_configs[0].arn : null
}