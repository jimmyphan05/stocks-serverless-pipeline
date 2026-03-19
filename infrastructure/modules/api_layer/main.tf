### IAM role for retrieval Lambda
resource "aws_iam_role" "retrieval_lambda_role" {
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
  role       = aws_iam_role.retrieval_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least privilege: read only access to DynamoDB
resource "aws_iam_role_policy" "dynamodb_read" {
  name = "${var.function_name}-dynamodb-read"
  role = aws_iam_role.retrieval_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dynamodb:Scan"]
      Resource = var.dynamodb_table_arn
    }]
  })
}

### Retrieval Lambda
resource "aws_lambda_function" "retrieval" {
  function_name    = var.function_name
  role             = aws_iam_role.retrieval_lambda_role.arn
  filename         = var.lambda_source_path
  source_code_hash = filebase64sha256(var.lambda_source_path)
  handler          = "retrieval.retrieval_lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      ENVIRONMENT         = var.environment
    }
  }
}

resource "aws_cloudwatch_log_group" "retrieval" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}

### API gateway
resource "aws_apigatewayv2_api" "stock_api" {
  name          = "stock-movers-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.stock_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.retrieval.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_movers" {
  api_id    = aws_apigatewayv2_api.stock_api.id
  route_key = "GET /movers"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.stock_api.id
  name        = "$default"
  auto_deploy = true
}

# Let API gateway invoke the retrieval Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.retrieval.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.stock_api.execution_arn}/*/*"
}