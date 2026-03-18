output "secret_arn" {
  description = "ARN of the Massive API key secret"
  value       = aws_secretsmanager_secret.massive_api_key.arn
}

output "secret_name" {
  description = "Name of the Massive API key secret"
  value       = aws_secretsmanager_secret.massive_api_key.name
}