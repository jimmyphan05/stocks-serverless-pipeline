variable "environment" {
  description = "Deployment environment (e.g. prod)"
  type        = string
}

variable "bucket_id" {
  description = "The ID (name) of the S3 bucket to use as the CloudFront origin"
  type        = string
}

variable "bucket_arn" {
  description = "The ARN of the S3 bucket to grant CloudFront OAC access"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket (e.g. bucket.s3.us-west-1.amazonaws.com)"
  type        = string
}