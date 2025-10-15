############################
# Lambda Assume Role Policy Document
# This data block creates an IAM policy document that allows AWS Lambda to assume a role.
# It is used as the trust policy for the Lambda execution role, enabling Lambda to use the permissions attached to the role.
############################
data "aws_iam_policy_document" "my_lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

############################
# Lambda Execution Role
# This resource creates an IAM role for the Lambda function to run with.
# The role uses the trust policy above, and will be attached to policies granting access to SQS and CloudWatch Logs.
# Tags are added for environment and role identification.
############################
resource "aws_iam_role" "my_lambda_role" {
  name               = "my_lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.my_lambda_assume_role.json

  tags = {
    Environment = "dev"
    Role        = "lambda-consumer"
  }
}

############################
# Lambda Permissions Policy Document
# This data block defines the permissions the Lambda function needs:
# - Access to poll, delete, and manage messages in the SQS queue.
# - Permission to create and write logs to CloudWatch Logs for monitoring and debugging.
# The resulting policy will be attached to the Lambda execution role.
############################
data "aws_iam_policy_document" "my_lambda_policy_doc" {
  ############################################
  # STATEMENT: Allow Lambda to interact with SQS
  # - sqs:ReceiveMessage            -> Poll messages
  # - sqs:DeleteMessage             -> Remove processed messages
  # - sqs:GetQueueAttributes        -> Read queue metadata (visibility timeout, etc.)
  # - sqs:ChangeMessageVisibility   -> Extend visibility while processing
  ############################################
  statement {
    sid    = "allowSQSPoll"
    effect = "Allow"

    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]

    resources = [aws_sqs_queue.my_sqs_queue.arn]
  }

  statement {
    sid    = "allowDynamoDB"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:TagResource",
    ]

    resources = [aws_dynamodb_table.my_dynamodb_table.arn]
  }

  statement {
    sid    = "allowLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      # NOTE: The wildcard * covers any log group / stream created by this function.
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
}

############################
# Lambda IAM Policy Resource
# This resource creates an IAM policy from the above document, which will be attached to the Lambda execution role.
# It grants the Lambda function the necessary permissions to interact with SQS and CloudWatch Logs.
############################
resource "aws_iam_policy" "my_lambda_policy" {
  name   = "s3-sqs-lambda-policy"
  policy = data.aws_iam_policy_document.my_lambda_policy_doc.json
}

############################
# Attach Policy to Lambda Role
# This resource attaches the custom IAM policy to the Lambda execution role, enabling the Lambda function to use the defined permissions.
############################
resource "aws_iam_role_policy_attachment" "my_lambda_policy_attachment" {
  # PURPOSE: Attach the custom inline policy (permissions defined above) to the Lambda role.
  # - role       -> Target IAM role name
  # - policy_arn -> ARN of the IAM policy granting SQS + CloudWatch Logs access
  role       = aws_iam_role.my_lambda_role.name
  policy_arn = aws_iam_policy.my_lambda_policy.arn
}


############################
# LAMBDA FUNCTIONS
############################


############################
# Lambda Source Packaging
# This data block uses the 'archive_file' provider to package the Lambda function source code (handler.py)
# into a zip file. This zip file is then uploaded to AWS Lambda as the function code.
#
# - 'type = "zip"': Specifies the archive type.
# - 'source_file': Path to the Python handler source file.
# - 'output_path': Where the zip file will be created for deployment.
#
# This approach allows you to keep Lambda code in source control and automate packaging.
############################
data "archive_file" "my_lambda_src" {
  type        = "zip"
  source_file = "${path.module}/lambda_src/handler.py"
  output_path = "${path.module}/lambda_src/lambda_src.zip"
}

############################
# Lambda Function Resource
# This resource creates the actual AWS Lambda function that will process messages from the SQS queue.
#
# - 'filename': Path to the deployment package (zip file) created above.
# - 'function_name': Name of the Lambda function in AWS.
# - 'role': IAM role ARN that the function will assume (grants SQS and logging permissions).
# - 'handler': The Python function to invoke (module.function_name).
# - 'runtime': Python version to use for the Lambda environment.
# - 'timeout': Max execution time in seconds (15s is typical for SQS consumers).
# - 'memory_size': Allocated memory (256MB is a good starting point for Python).
# - 'environment': Environment variables for the function (e.g., target bucket for future use).
# - 'tags': Metadata for cost allocation and management.
#
# The function code should be in 'lambda_src/handler.py' and must define a 'lambda_handler' entry point.
############################
resource "aws_lambda_function" "my_lambda_function" {
  filename         = data.archive_file.my_lambda_src.output_path
  function_name    = "s3-sqs-message-consumer"
  role             = aws_iam_role.my_lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.my_lambda_src.output_base64sha256 # Ensures updates are detected & triggers a new deploy when code changes

  runtime     = "python3.11"
  timeout     = 15
  memory_size = 256

  environment {
    variables = {
      TARGET_BUCKET       = "to-be-added-later" # Placeholder for phase 2 (future S3 target)
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.my_dynamodb_table.name
      AWS_REGION          = var.region
      AWS_ENDPOINT_URL    = var.dynamodb_endpoint
    }
  }
  tags = {
    Environment = "dev"
    Function    = "s3-sqs-consumer"
  }
}

############################
# EVENT SOURCE MAPPING (SQS -> LAMBDA)
############################

############################
# Lambda Event Source Mapping (SQS to Lambda)
# This resource connects the SQS queue to the Lambda function, so that messages in the queue
# automatically trigger the Lambda for processing.
#
# - 'event_source_arn': ARN of the SQS queue to poll for messages.
# - 'function_name': ARN of the Lambda function to invoke.
# - 'batch_size': Number of messages to send to the Lambda in each batch (tune for performance).
# - 'maximum_batching_window_in_seconds': Max time to wait for batch to fill before invoking Lambda.
# - 'enabled': Whether this mapping is active.
#
# This is the key resource that wires up the event-driven architecture: S3 events -> SQS -> Lambda.
############################
resource "aws_lambda_event_source_mapping" "my_sqs_to_lambda_mapping" {
  event_source_arn                   = aws_sqs_queue.my_sqs_queue.arn
  function_name                      = aws_lambda_function.my_lambda_function.arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 2
  enabled                            = true
  # TUNING NOTES:
  # - batch_size: Increase for higher throughput (ensure function handles batch semantics).
  # - maximum_batching_window_in_seconds: Small window => low latency; larger window => fuller batches.
  # - enable filtering or DLQ in future for poison message handling.
}


