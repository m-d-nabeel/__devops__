############################
# S3 Bucket Resource
# Creates the main S3 bucket that will be used as the source for S3 events.
############################
resource "aws_s3_bucket" "my_bucket" {
  bucket        = "my-s3-sqs-trigger-bucket" # NOTE: S3 bucket names are global. Change if apply errors due to existing bucket.
  force_destroy = true
  tags = {
    Name        = "source-bucket"
    Environment = "dev"
    Stack       = "s3-sqs-lambda"
  }
}

############################
# S3 Bucket Server Side Encryption
# Enables default server-side encryption (SSE) using AES256 for all objects in the bucket.
############################
resource "aws_s3_bucket_server_side_encryption_configuration" "my_bucket_encryption" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

############################
# S3 Bucket Ownership Controls
# Sets the bucket's object ownership to prefer the bucket owner for all new objects.
############################
resource "aws_s3_bucket_ownership_controls" "my_bucket_ownership" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

############################
# S3 Bucket Public Access Block
# Blocks all forms of public access to the S3 bucket for security.
############################
resource "aws_s3_bucket_public_access_block" "my_bucket_pab" {
  bucket                  = aws_s3_bucket.my_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

############################
# S3 Bucket ACL
# Sets the bucket's Access Control List (ACL) to private and ensures ownership controls are applied first.
############################
resource "aws_s3_bucket_acl" "my_bucket_acl" {
  bucket     = aws_s3_bucket.my_bucket.id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.my_bucket_ownership]
}
