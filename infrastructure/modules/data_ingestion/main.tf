### IAM role for data ingestion lambda
resource "aws_iam_role" "ingestion_lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.ingestion_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least privilege: allow write access to dynamoDB
resource "aws_iam_role_policy" "dynamodb_write" {
  name = "${var.function_name}-dynamodb-write"
  role = aws_iam_role.ingestion_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
      Resource = var.dynamodb_table_arn
    }]
  })
}

# Allow to read API key from secrets manager
resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.function_name}-secrets-read"
  role = aws_iam_role.ingestion_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = var.secret_arn
    }]
  })
}

### Stock API data ingestion lambda
resource "aws_lambda_function" "ingestion" {
  function_name    = var.function_name
  role             = aws_iam_role.ingestion_lambda_role.arn
  filename         = var.lambda_source_path
  source_code_hash = filebase64sha256(var.lambda_source_path)
  handler          = "ingestion.ingestion_lambda_handler"
  runtime          = "python3.12"
  timeout          = 120

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      SECRET_ARN          = var.secret_arn
      WATCHLIST           = join(",", var.watchlist)
      ENVIRONMENT         = var.environment
    }
  }
}

resource "aws_cloudwatch_log_group" "ingestion" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}

### Eventbridge rule (cron job) to trigger lambda daily after market closes
resource "aws_cloudwatch_event_rule" "daily_trigger" {
  name                = "${var.function_name}-daily-trigger"
  description         = "Triggers stock ingestion Lambda daily after market closes"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "invoke_lambda" {
  rule      = aws_cloudwatch_event_rule.daily_trigger.name
  target_id = "IngestionLambda"
  arn       = aws_lambda_function.ingestion.arn
}

# Allow eventbridge to invoke ingestion lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_trigger.arn
}