output "api_endpoint" {
  description = "Base URL of the API Gateway"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "movers_url" {
  description = "Full URL for the GET /movers endpoint"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/movers"
}

output "lambda_function_name" {
  description = "Name of the retrieval Lambda function"
  value       = aws_lambda_function.retrieval.function_name
}