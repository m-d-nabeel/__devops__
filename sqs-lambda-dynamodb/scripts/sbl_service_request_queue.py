#!/usr/bin/env python3
"""Send a sample message to the LocalStack-backed SQS queue."""

from __future__ import annotations

import importlib
import json
import os
import random
import time
from datetime import datetime, timezone
from pathlib import Path

import boto3

try:
    Faker = importlib.import_module("faker").Faker
except ModuleNotFoundError as exc:
    raise SystemExit(
        "Faker library is required. Install with 'pip install faker'."
    ) from exc


QUEUE_NAME = os.environ.get("QUEUE_NAME", "sbl_service_request_queue")
AWS_REGION = os.environ.get("AWS_REGION", "us-east-1")
AWS_ENDPOINT_URL = os.environ.get("AWS_ENDPOINT_URL", "http://localhost:4566")
TABLE_NAME = "sbl_service_account_request"
STATUS_OPTIONS = ["requested", "processing", "success", "failed"]
CSP_OPTIONS = ["aws", "azure", "gcp", "oci"]
POLL_INTERVAL_SECONDS = 1
POLL_TIMEOUT_SECONDS = 60
OUTPUT_FILE = Path(__file__).parent / "sbl_service_account_request_dump.json"

faker = Faker()


def save_all_items(table) -> None:
    items = []
    exclusive_start_key = None

    while True:
        scan_kwargs = {}
        if exclusive_start_key:
            scan_kwargs["ExclusiveStartKey"] = exclusive_start_key

        response = table.scan(**scan_kwargs)
        items.extend(response.get("Items", []))
        exclusive_start_key = response.get("LastEvaluatedKey")

        if not exclusive_start_key:
            break

    with OUTPUT_FILE.open("w", encoding="utf-8") as outfile:
        json.dump(items, outfile, indent=2, default=str)

    print(
        json.dumps(
            {"status": "saved", "file": str(OUTPUT_FILE), "count": len(items)}, indent=2
        )
    )


def build_message() -> dict:
    now = datetime.now(timezone.utc)
    created_by = faker.email()
    modified_by = faker.email()
    return {
        "tenant_id": faker.unique.pystr(min_chars=6, max_chars=12),
        "account_id": faker.bothify(text="acct-########"),
        "service_name": faker.bs().replace(" ", "_").lower(),
        "request_id": f"req-{now.strftime('%Y%m%d%H%M%S')}-{faker.pystr(min_chars=4, max_chars=6)}",
        "version": f"v{faker.random_int(min=1, max=5)}",
        "csp": random.choice(CSP_OPTIONS),
        "deployment_group_status": random.choice(STATUS_OPTIONS),
        "service_enaablement_status": random.choice(STATUS_OPTIONS),
        "created_by": created_by,
        "created_at": now.isoformat(),
        "last_modified_at": now.isoformat(),
        "last_modified_source_date": now.isoformat(),
        "last_modified_source_by": modified_by,
    }


def main() -> None:
    sqs = boto3.client("sqs", region_name=AWS_REGION, endpoint_url=AWS_ENDPOINT_URL)
    dynamodb = boto3.resource(
        "dynamodb", region_name=AWS_REGION, endpoint_url=AWS_ENDPOINT_URL
    )
    table = dynamodb.Table(TABLE_NAME)

    queue_url = sqs.get_queue_url(QueueName=QUEUE_NAME)["QueueUrl"]

    message_body = build_message()

    response = sqs.send_message(
        QueueUrl=queue_url, MessageBody=json.dumps(message_body)
    )

    request_id = message_body["request_id"]
    tenant_id = message_body["tenant_id"]
    print(
        json.dumps(
            {
                "queue_url": queue_url,
                "message_id": response["MessageId"],
                "request_id": request_id,
                "tenant_id": tenant_id,
            },
            indent=2,
        )
    )

    start_time = time.monotonic()
    deadline = start_time + POLL_TIMEOUT_SECONDS
    item = None

    while time.monotonic() < deadline:
        result = table.get_item(
            Key={"request_id": request_id, "tenant_id": tenant_id},
            ConsistentRead=True,
        )
        item = result.get("Item")
        if item:
            elapsed = time.monotonic() - start_time
            print(
                json.dumps(
                    {"status": "inserted", "elapsed_seconds": round(elapsed, 3)},
                    indent=2,
                )
            )
            break
        time.sleep(POLL_INTERVAL_SECONDS)

    if item is None:
        print(
            json.dumps(
                {
                    "status": "timeout",
                    "message": f"Item with request_id {request_id} not found within {POLL_TIMEOUT_SECONDS}s",
                },
                indent=2,
            )
        )
    else:
        save_all_items(table)


if __name__ == "__main__":
    main()
