terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider
      version = "6.0.0"     # 5.x is more compatible with LocalStack for DynamoDB
    }
  }
}

provider "aws" {
  region                      = var.region
  access_key                  = var.aws_access_key
  secret_key                  = var.aws_secret_key
  skip_region_validation      = true
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true

  endpoints {
    iam      = var.iam_endpoint
    s3       = var.s3_endpoint
    sqs      = var.sqs_endpoint
    lambda   = var.lambda_endpoint
    sts      = var.sts_endpoint
    dynamodb = var.dynamodb_endpoint
    logs     = var.logs_endpoint
  }
}
