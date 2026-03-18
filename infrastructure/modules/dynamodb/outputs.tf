output "table_name" {
  description = "Table name"
  value       = aws_dynamodb_table.stock_movers.name
}

output "table_arn" {
  description = "ARN of the table"
  value       = aws_dynamodb_table.stock_movers.arn
}