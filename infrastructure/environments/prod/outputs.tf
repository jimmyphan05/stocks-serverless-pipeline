output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.dynamodb.table_name
}

output "secret_arn" {
  description = "Secrets Manager ARN for the Massive API key"
  value       = module.secrets_manager.secret_arn
}

output "lambda_function_name" {
  description = "Ingestion Lambda function name"
  value       = module.data_ingestion.lambda_function_name
}