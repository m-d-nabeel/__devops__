variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = "test-access-key"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = "test-secret-key"
}

variable "localstack_endpoint" {
  description = "LocalStack CLI Endpoint URL"
  type        = string
  default     = "http://localhost.localstack.cloud:4566"
}
