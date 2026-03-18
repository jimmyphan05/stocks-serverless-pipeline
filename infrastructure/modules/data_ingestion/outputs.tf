output "lambda_arn" {
  description = "ARN of the ingestion Lambda function"
  value       = aws_lambda_function.ingestion.arn
}

output "lambda_function_name" {
  description = "Name of the ingestion Lambda function"
  value       = aws_lambda_function.ingestion.function_name
}

output "lambda_role_arn" {
  description = "ARN of the ingestion Lambda IAM role"
  value       = aws_iam_role.ingestion_lambda_role.arn
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge daily trigger rule"
  value       = aws_cloudwatch_event_rule.daily_trigger.arn
}