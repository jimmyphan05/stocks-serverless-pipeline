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

output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = module.api_layer.api_endpoint
}

output "movers_url" {
  description = "Full URL for GET /movers"
  value       = module.api_layer.movers_url
}

output "frontend_url" {
  description = "CloudFront HTTPS URL for the frontend"
  value       = module.cloudfront.cloudfront_url
}

output "frontend_bucket_name" {
  description = "S3 bucket name for deploying frontend files"
  value       = module.s3_frontend.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (used for cache invalidations)"
  value       = module.cloudfront.distribution_id
}