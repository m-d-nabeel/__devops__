module "sbl_service_account_request_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name                     = "sbl_service_account_request_handler"
  handler                           = "handler.lambda_handler"
  runtime                           = "python3.12"
  description                       = "Processes service requests from SQS and stores them in DynamoDB"
  timeout                           = 30 # Maximum allowed timeout for Lambda to process a batch of messages
  memory_size                       = 512
  maximum_retry_attempts            = 2   # Retry twice on failure before sending to DLQ
  maximum_event_age_in_seconds      = 600 # Discard messages older than 10 minutes
  cloudwatch_logs_retention_in_days = 30  # Retain logs for 30 days for monitoring and debugging

  vpc_subnet_ids = [aws_vpc.sbl_service_request_vpc.id]
  vpc_security_group_ids = [
    "sg-085912345678492fb" # Replace with your actual security group IDs
  ]

  role_path             = "/sbl-service-account-request/"
  attach_network_policy = true

  environment_variables = {
    TABLE_NAME       = aws_dynamodb_table.sbl_service_acccount_request.name
    AWS_REGION       = var.region
    AWS_ENDPOINT_URL = var.dynamodb_endpoint
    QUEUE_NAME       = aws_sqs_queue.sbl_service_request_queue.name
  }

  source_path = [
    {
      path             = "lambda_src"
      pip_requirements = "lambda_src/requirements.txt"
    }
  ]

  attach_policy_statements = true

  policy_statements = {

    sqs_access = {
      effect = "Allow"

      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ]

      resources = [aws_sqs_queue.sbl_service_request_queue.arn]
    }

    dynamodb_access = {
      effect = "Allow"

      actions = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DescribeTable"
      ]

      resources = [aws_dynamodb_table.sbl_service_acccount_request.arn]
    }
  }

  tags = {
    Environment = "production"
    Team        = "sbl"
  }
}

resource "aws_lambda_event_source_mapping" "sbl_service_request" {
  event_source_arn                   = aws_sqs_queue.sbl_service_request_queue.arn
  function_name                      = module.sbl_service_account_request_lambda.lambda_function_arn
  batch_size                         = 5
  maximum_batching_window_in_seconds = 0 # The maximum amount of time to wait before sending a batch to Lambda, even if the batch is not full. Eg. 5 seconds.
  maximum_retry_attempts             = 2
  enabled                            = true
  function_response_types            = ["ReportBatchItemFailures"] # Enable partial batch failure handling
}
