terraform {
  backend "s3" {
    bucket = "stocks-pipeline-terraform-state"
    key    = "prod/terraform.tfstate"
    region = "us-west-1"
  }
}
