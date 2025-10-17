resource "aws_vpc" "global_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    Name        = "global-vpc"
    Environment = "production"
    Team        = "sbl"
  }
}
