module "dynamodb" {
  source = "../../modules/dynamodb"

  table_name  = "stock-movers-${var.environment}"
  environment = var.environment
}

module "secrets_manager" {
  source = "../../modules/secrets_manager"

  secret_name     = "stocks-pipeline/massive-api-key-${var.environment}"
  massive_api_key = var.massive_api_key
  environment     = var.environment
}

module "data_ingestion" {
  source = "../../modules/data_ingestion"

  environment         = var.environment
  function_name       = "stock-ingestion-${var.environment}"
  lambda_source_path  = "${path.module}/../../../backend/ingestion_lambda/lambda.zip"
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
  secret_arn          = module.secrets_manager.secret_arn
}
