############################
# SQS Queue Resource
# Creates the SQS queue that will receive event notifications from the S3 bucket.
############################
resource "aws_sqs_queue" "my_sqs_queue" {
  name = "my-s3-sqs-trigger-queue"

  ############################################
  # QUEUE TUNING
  # visibility_timeout_seconds : Should exceed Lambda max processing time (timeout=15s). Using 60s for buffer + retry margin.
  # receive_wait_time_seconds  : Long polling reduces empty receives (cost + throttle). 5s is a safe starter value.
  ############################################
  visibility_timeout_seconds = 60
  receive_wait_time_seconds  = 5
  # message_retention_seconds = 345600  # (Optional) Default = 4 days; uncomment to be explicit.
  # FUTURE: redrive_policy (DLQ) for poison messages once error handling pattern chosen.

  tags = {
    Name        = "primary-queue"
    Environment = "dev"
  }
}

############################
# SQS Queue Policy
# Allows the S3 bucket to send messages to the SQS queue by attaching the appropriate policy.
############################
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.my_sqs_queue.id
  policy    = data.aws_iam_policy_document.allow_s3_to_sqs.json
}

############################
# S3 Bucket Notification
# Configures the S3 bucket to send object created events to the SQS queue.
############################
resource "aws_s3_bucket_notification" "my_bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  queue {
    queue_arn = aws_sqs_queue.my_sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
    # OPTIONAL FILTERS:
    # filter_prefix = "images/"  # Trigger only for keys starting with 'images/'
    # filter_suffix = ".jpg"     # Trigger only for .jpg files
  }

  # Ensure queue policy allowing S3 -> SQS is in place before configuring notifications
  depends_on = [aws_sqs_queue_policy.allow_s3]
}

############################
# AWS Caller Identity Data Source
# Retrieves information about the current AWS account (used for policy conditions).
############################
data "aws_caller_identity" "current" {}

############################
# IAM Policy Document Data Source
# Generates a policy document that allows S3 to send messages to the SQS queue, with conditions for security.
############################
data "aws_iam_policy_document" "allow_s3_to_sqs" {
  statement {
    sid    = "AllowS3SendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = ["sqs:SendMessage"]

    resources = [aws_sqs_queue.my_sqs_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.my_bucket.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
