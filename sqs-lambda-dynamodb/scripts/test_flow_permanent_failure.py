#!/usr/bin/env python3
"""Push a permanent failure message and show Lambda logs for the drop."""

import json
import time
import uuid

import boto3

AWS_REGION = "us-east-1"
AWS_ENDPOINT = "http://localhost.localstack.cloud:4566"
AWS_ACCESS_KEY = "test-access-key"
AWS_SECRET_KEY = "test-secret-key"
QUEUE_NAME = "sbl-service-request-queue"
LOG_GROUP = "/aws/lambda/sbl-service-request-processor"

sqs = boto3.client(
    "sqs",
    region_name=AWS_REGION,
    endpoint_url=AWS_ENDPOINT,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
)
logs = boto3.client(
    "logs",
    region_name=AWS_REGION,
    endpoint_url=AWS_ENDPOINT,
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
)

queue_url = sqs.get_queue_url(QueueName=QUEUE_NAME)["QueueUrl"]
message_id = str(uuid.uuid4())
body = {
    "request_id": message_id,
    "tenant_id": "tenant-permanent",
    "service_name": "demo_permanent",
    "simulate": "permanent",
    "reason": "forced permanent failure",
}

start_ms = int(time.time() * 1000)
response = sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(body))

print(json.dumps({
    "queueUrl": queue_url,
    "messageId": response["MessageId"],
    "requestId": message_id,
}, indent=2))

time.sleep(5)

log_events = logs.filter_log_events(
    logGroupName=LOG_GROUP,
    startTime=start_ms,
    filterPattern=f'"{message_id}"',
)

print(json.dumps({
    "logEvents": [
        {
            "timestamp": event.get("timestamp"),
            "message": event.get("message"),
        }
        for event in log_events.get("events", [])
    ]
}, indent=2))
