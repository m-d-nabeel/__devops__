############################
# Terraform AWS Provider Configuration
#
# This file sets up the required provider and configures the AWS provider for the project.
#
# - The 'terraform' block specifies the AWS provider source and version constraint.
# - The 'provider' block configures the AWS region for all resources in this deployment.
#
# All other resource files (S3, SQS, Lambda, etc.) depend on this configuration.
############################

terraform {
  ############################################
  # VERSION CONSTRAINTS
  # - required_version ensures collaborators use a modern Terraform CLI (adjust as needed)
  # - required_providers pins AWS provider to a safe minor series to avoid unexpected breaking changes.
  ############################################
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws" # Official AWS provider
      version = "~> 5.49.0"     # 5.x is more compatible with LocalStack for DynamoDB
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
  }
}
