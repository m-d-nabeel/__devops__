# data "aws_iam_policy_document" "allow_s3_send" {
#   statement {
#     effect = "Allow"

#     principals {
#       type        = "Service"
#       identifiers = ["s3.amazonaws.com"]
#     }

#     actions   = ["sqs:SendMessage"]
#     resources = [aws_sqs_queue.my_sqs_queue.arn]

#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values   = [aws_s3_bucket.my_s3_bucket.arn]
#     }
#   }
# }
