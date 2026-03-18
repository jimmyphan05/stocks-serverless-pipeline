variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "function_name" {
  description = "Name of the ingestion Lambda function"
  type        = string
}

variable "lambda_source_path" {
  description = "Path to the zipped Lambda deployment package"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table to write results to"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table to write results to"
  type        = string
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Massive API key"
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge cron schedule (UTC)"
  type        = string
  default     = "cron(10 20 * * ? *)" # 4:10 PM ET = 8:10 PM UTC, 10 minute buffer at market close to ensure data is available
}

variable "watchlist" {
  description = "List of stock ticker symbols to track"
  type        = list(string)
  default     = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
}