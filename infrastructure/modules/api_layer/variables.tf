variable "environment" {
  description = "Deployment environment (e.g. prod)"
  type        = string
}

variable "function_name" {
  description = "Name of the retrieval Lambda function"
  type        = string
}

variable "lambda_source_path" {
  description = "Path to the retrieval Lambda zip file"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name to read from"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table"
  type        = string
}