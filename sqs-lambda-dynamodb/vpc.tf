resource "aws_security_group" "sbl_lambda_sg" {
  name        = "lambda-vpc-sg"
  description = "Security group for Lambda functions in VPC"
  vpc_id      = aws_vpc.sbl_service_request_vpc.id

  egress = [{
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
}

resource "aws_vpc" "sbl_service_request_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true # Allow instances to resolve public DNS names
  enable_dns_support   = true # Enable DNS resolution in the VPC

  tags = {
    Name        = "sbl_service_request_vpc"
    Environment = "production"
    Team        = "sbl"
  }
}
