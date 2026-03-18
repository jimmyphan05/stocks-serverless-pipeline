variable "secret_name" {
  description = "Name of secret"
  type        = string
}

variable "massive_api_key" {
  description = "API key for Massive stock API"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}