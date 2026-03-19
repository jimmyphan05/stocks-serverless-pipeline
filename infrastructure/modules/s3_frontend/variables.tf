variable "environment" {
  description = "Deployment environment (e.g. prod)"
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for the frontend"
  type        = string
}