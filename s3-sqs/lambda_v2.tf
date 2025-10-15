########################################
# Lambda implementation using terraform-aws-modules/lambda/aws
# This module handles packaging, IAM, and the SQS trigger wiring.
# Comment markers align each section with the verbose resources in lambda.tf.
########################################
module "my_lambda_v2" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  # Matches aws_lambda_function.my_lambda_function configuration.
  function_name = "s3-sqs-message-consumer"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"

  # Mirrors data.archive_file.my_lambda_src by packaging the handler directory for us.
  source_path = "${path.module}/lambda_src"

  # Replaces the environment block inside aws_lambda_function.my_lambda_function.
  environment_variables = {
    TARGET_BUCKET       = "to-be-added-later"
    DYNAMODB_TABLE_NAME = aws_dynamodb_table.my_dynamodb_table.name
    AWS_REGION          = var.region
    AWS_ENDPOINT_URL    = var.dynamodb_endpoint
  }

  # Combines aws_iam_policy.my_lambda_policy + aws_iam_role_policy_attachment.my_lambda_policy_attachment.
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.my_lambda_policy_doc.json

  # Replaces aws_lambda_event_source_mapping.my_sqs_to_lambda_mapping with the module's trigger wiring.
  create_current_version_allowed_triggers = true
  allowed_triggers = {
    sqs = {
      principal  = "sqs.amazonaws.com"
      source_arn = aws_sqs_queue.my_sqs_queue.arn
    }
  }
}
