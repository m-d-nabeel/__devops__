terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider
      version = "6.0.0"         # 5.x is more compatible with LocalStack for DynamoDB
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
    iam      = var.localstack_endpoint
    s3       = var.localstack_endpoint
    sqs      = var.localstack_endpoint
    lambda   = var.localstack_endpoint
    sts      = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
    logs     = var.localstack_endpoint
    ec2      = var.localstack_endpoint
  }
}
