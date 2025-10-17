variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key" {
  description = "AWS Access Key"
  type        = string
  default     = "test"
}

variable "aws_secret_key" {
  description = "AWS Secret Key"
  type        = string
  default     = "test"
}

variable "localstack_endpoint" {
  description = "LocalStack CLI Endpoint URL"
  type        = string
  default     = "http://localhost.localstack.cloud:4566"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.15.28.0/22"
}
