module "sbl_service_account_request_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.1.0"

  function_name = "sbl-service-request-processor"
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  description   = "Processes service requests from SQS and stores them in DynamoDB"
  timeout       = 30 # Maximum allowed timeout for Lambda to process a batch of messages
  memory_size   = 256
  publish       = false

  source_path = [{
    path = "${path.module}/lambda_src"
  }]

  environment_variables = {
    AWS_ENDPOINT_URL   = var.localstack_endpoint
    MAX_RETRY_ATTEMPTS = 2
  }

  role_path                         = "/sbl-service-request-processor/"
  attach_network_policy             = false
  attach_policy_statements          = true
  cloudwatch_logs_retention_in_days = 30 # Retain logs for 30 days for monitoring and debugging

  policy_statements = {
    dynamodb_access = {
      effect = "Allow"

      actions = [
        "dynamodb:Scan",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:BatchWriteItem",
      ]

      resources = [aws_dynamodb_table.sbl_service_acccount_request.arn]
    }

    sqs_access = {
      effect = "Allow"

      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
      ]

      resources = [aws_sqs_queue.sbl_service_request_queue.arn]
    }
  }

  vpc_security_group_ids = [aws_security_group.sbl_service_request_lambda_sq.id]

  tags = {
    Environment = "production"
    Team        = "sbl"
  }

  depends_on = [aws_sqs_queue.sbl_service_request_queue]
}

resource "aws_lambda_event_source_mapping" "sbl_service_request" {
  event_source_arn        = aws_sqs_queue.sbl_service_request_queue.arn
  function_name           = module.sbl_service_account_request_lambda.lambda_function_arn
  batch_size              = 5
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"] # Enable partial batch failure handling

  depends_on = [module.sbl_service_account_request_lambda]
  # maximum_batching_window_in_seconds = 0 # The maximum amount of time to wait before sending a batch to Lambda, even if the batch is not full. Eg. 5 seconds.
  # # Note: maximum_retry_attempts is not applicable for SQS event sources in event source mapping.
  # # Retries for SQS are managed by the queue's redrive policy and Lambda's default behavior.
  # maximum_retry_attempts             = 2
}

resource "aws_security_group" "sbl_service_request_lambda_sq" {
  name        = "sbl-service-request-lambda-sg"
  description = "Allow traffic to SBL Service Request Lambda"
  vpc_id      = aws_vpc.global_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Team        = "sbl"
  }
}
