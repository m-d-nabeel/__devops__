# Minimal Makefile to test S3 -> SQS on LocalStack

# Config
AWS_ENDPOINT := http://localhost:4566
AWS_REGION   := us-east-1

AWS_ACCESS_KEY_ID     := test_access_key
AWS_SECRET_ACCESS_KEY := test_secret_key

AWS_S3_BUCKET      := my-s3-sqs-local-bucket
AWS_SQS_QUEUE_NAME := my-s3-sqs-local-queue

# Defaults for tests
OBJECT_KEY ?= foo/test.log   # Keep .log to match your S3 suffix filter
FILE       ?= /tmp/test.log
WAIT       ?= 5
MAX_MSGS   ?= 10

# Export creds/region
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION

AWS := aws --endpoint-url=$(AWS_ENDPOINT) --region=$(AWS_REGION)

.PHONY: put-object recv

# Create (if missing) and upload a .log object to S3
put-object:
	@test -f "$(FILE)" || echo "hello from localstack" > "$(FILE)"
	$(AWS) s3 cp "$(FILE)" "s3://$(AWS_S3_BUCKET)/$(OBJECT_KEY)"

# Receive messages from the SQS queue (long poll)
recv:
	@QURL=$$($(AWS) sqs get-queue-url --queue-name "$(AWS_SQS_QUEUE_NAME)" --query 'QueueUrl' --output text); \
	$(AWS) sqs receive-message --queue-url $$QURL --wait-time-seconds $(WAIT) --max-number-of-messages $(MAX_MSGS) | (command -v jq >/dev/null 2>&1 && jq . || cat)