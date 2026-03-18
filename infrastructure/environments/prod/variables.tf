variable "aws_region" {
  description = "aws region to deploy in"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "massive_api_key" {
  description = "API key for the Massive stock API"
  type        = string
  sensitive   = true
}