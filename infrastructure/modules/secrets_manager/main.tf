resource "aws_secretsmanager_secret" "massive_api_key" {
  name                    = var.secret_name
  description             = "API key for Massive stock data API"
  recovery_window_in_days = 0 # allows immediate deletion for dev/teardown

  tags = {
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "massive_api_key" {
  secret_id     = aws_secretsmanager_secret.massive_api_key.id
  secret_string = jsonencode({ api_key = var.massive_api_key })
}