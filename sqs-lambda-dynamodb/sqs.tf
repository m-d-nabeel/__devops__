resource "aws_sqs_queue" "sbl_service_request_dlq" {
  name                      = "sbl_service_request_dlq"
  message_retention_seconds = 1209600 # 14 days to keep failed messages for inspection
  max_message_size          = 262144  # 256 KB
  receive_wait_time_seconds = 20      # Enable long polling to reduce empty receives
  sqs_managed_sse_enabled   = true

  tags = {
    Environment   = "production"
    Team          = "sbl"
    Functionality = "SblServiceRequestQueueDLQ"
  }
}

resource "aws_sqs_queue" "sbl_service_request_queue" {
  name                              = "sbl_service_request_queue"
  delay_seconds                     = 0
  visibility_timeout_seconds        = 90      # Slightly above Lambda timeout (900s) to prevent premature retries
  message_retention_seconds         = 1209600 # 14 days to align with DLQ retention 
  max_message_size                  = 262144  # 256 KB
  receive_wait_time_seconds         = 0       # Enable long polling to reduce API calls and latency
  content_based_deduplication       = false
  kms_master_key_id                 = "alias/aws/sqs" # Use AWS managed key for SQS encryption
  kms_data_key_reuse_period_seconds = 300             # Reuse data key for 5 minutes to balance security and performance
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.sbl_service_request_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Environment   = "production"
    Team          = "sbl"
    Functionality = "SblServiceRequestQueue"
  }
}
