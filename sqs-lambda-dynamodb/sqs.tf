resource "aws_sqs_queue" "sbl_service_request_queue" {
  name                              = "sbl-service-request-queue"
  visibility_timeout_seconds        = 4 * 30            # Slightly above Lambda timeout (900s) to prevent premature retries
  message_retention_seconds         = 14 * 24 * 60 * 60 # 14 days to align with DLQ retention 
  max_message_size                  = 262144            # 256 KB
  delay_seconds                     = 0
  receive_wait_time_seconds         = 20              # Enable long polling to reduce API calls and latency
  kms_master_key_id                 = "alias/aws/sqs" # Use AWS managed key for SQS encryption
  kms_data_key_reuse_period_seconds = 300             # Reuse data key for 5 minutes to balance security and performance

  tags = {
    Environment   = "production"
    Team          = "sbl"
    Functionality = "SblServiceRequestQueue"
  }

  # # Non-FIFO queue settings
  # fifo_queue                  = false
  # content_based_deduplication = false
}
