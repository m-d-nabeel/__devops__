#!/usr/bin/env python

"""Push a transient failure message and display retry-related Lambda logs."""

import json
import time
import uuid

import boto3

AWS_REGION = "us-east-1"
AWS_ENDPOINT = "http://localhost:4566"
QUEUE_NAME = "sbl-service-request-queue"
LOG_GROUP = "/aws/lambda/sbl-service-request-processor"
WAIT_SECONDS = 12

sqs = boto3.client("sqs", region_name=AWS_REGION, endpoint_url=AWS_ENDPOINT)
logs = boto3.client("logs", region_name=AWS_REGION, endpoint_url=AWS_ENDPOINT)

queue_url = sqs.get_queue_url(QueueName=QUEUE_NAME)["QueueUrl"]
message_id = str(uuid.uuid4())
body = {
    "request_id": message_id,
    "tenant_id": "tenant-transient",
    "service_name": "demo_transient",
    "simulate": "transient",
    "reason": "forced transient error",
}

start_ms = int(time.time() * 1000)
response = sqs.send_message(QueueUrl=queue_url, MessageBody=json.dumps(body))

print(json.dumps({
    "queueUrl": queue_url,
    "messageId": response["MessageId"],
    "requestId": message_id,
    "waitSeconds": WAIT_SECONDS,
}, indent=2))

for remaining in range(WAIT_SECONDS, 0, -1):
    print(json.dumps({"waiting": remaining}))
    time.sleep(1)

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
