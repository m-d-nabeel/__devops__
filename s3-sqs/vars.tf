############################
# Terraform Variables
#
# This file defines input variables for the Terraform configuration.
#
# - 'region': Specifies the AWS region where all resources will be deployed.
#   - Can be overridden from the command line or in a tfvars file.
#   - Default is 'us-east-1'.
#
# Additional variables can be added here as the infrastructure grows.
############################

variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
}

variable "iam_endpoint" {
  description = "IAM Endpoint URL"
  type        = string
}

variable "s3_endpoint" {
  description = "S3 Endpoint URL"
  type        = string
}

variable "sqs_endpoint" {
  description = "SQS Endpoint URL"
  type        = string
}

variable "lambda_endpoint" {
  description = "Lambda Endpoint URL"
  type        = string
}

variable "sts_endpoint" {
  description = "STS Endpoint URL"
  type        = string
}

variable "dynamodb_endpoint" {
  description = "DynamoDB Endpoint URL"
  type        = string
}