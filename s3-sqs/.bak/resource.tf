# resource "aws_s3_bucket" "my_s3_bucket" {
#   bucket = "my-s3-sqs-local-bucket"
# }

# resource "aws_s3_bucket_acl" "my_s3_bucket_acl" {
#   bucket = aws_s3_bucket.my_s3_bucket.id
#   acl    = "public-read"
# }

# resource "aws_sqs_queue" "my_sqs_queue" {
#   name = "my-s3-sqs-local-queue"
# }

# resource "aws_sqs_queue_policy" "allow_s3_to_sqs" {
#   queue_url = aws_sqs_queue.my_sqs_queue.id
#   policy    = data.aws_iam_policy_document.allow_s3_send.json
# }

# resource "aws_s3_bucket_notification" "my_s3_notification" {
#   bucket = aws_s3_bucket.my_s3_bucket.id
#   queue {
#     queue_arn     = aws_sqs_queue.my_sqs_queue.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".log"
#   }
#   depends_on = [aws_sqs_queue.my_sqs_queue]
# }
