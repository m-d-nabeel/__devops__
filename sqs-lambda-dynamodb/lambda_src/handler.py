import json
import os
import uuid
from datetime import datetime, timezone
from typing import TypedDict

import boto3


class SblServiceAccountRequest(TypedDict):
    request_id: str
    tenant_id: str
    account_id: str
    service_name: str
    version: str
    csp: str
    deployment_group_status: str
    service_enaablement_status: str
    created_by: str
    created_at: str
    last_modified_at: str
    last_modified_source_date: str
    last_modified_source_by: str


def _iso_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _build_item(payload: dict) -> SblServiceAccountRequest:
    now_iso = _iso_now()
    created_at = payload.get("created_at", now_iso)
    last_modified_at = payload.get("last_modified_at", created_at)
    last_modified_source_date = payload.get("last_modified_source_date", last_modified_at)
    created_by = payload.get("created_by", "system")

    return {
        "request_id": payload.get("request_id", str(uuid.uuid4())),
        "tenant_id": payload.get("tenant_id", str(uuid.uuid4())),
        "account_id": payload.get("account_id", str(uuid.uuid4())),
        "service_name": payload.get("service_name", "unknown-service"),
        "version": payload.get("version", "v1"),
        "csp": payload.get("csp", "aws"),
        "deployment_group_status": payload.get("deployment_group_status", "requested"),
        "service_enaablement_status": payload.get("service_enaablement_status", "requested"),
        "created_by": created_by,
        "created_at": created_at,
        "last_modified_at": last_modified_at,
        "last_modified_source_date": last_modified_source_date,
        "last_modified_source_by": payload.get("last_modified_source_by", created_by),
    }


def _dynamodb_resource() -> boto3.resources.base.ServiceResource:
    endpoint_url = os.environ.get("AWS_ENDPOINT_URL")
    region_name = os.environ.get("AWS_REGION", "us-east-1")
    if endpoint_url:
        return boto3.resource(
            "dynamodb", endpoint_url=endpoint_url, region_name=region_name
        )
    return boto3.resource("dynamodb", region_name=region_name)


def lambda_handler(event, context):
    table_name = os.environ["TABLE_NAME"]
    dynamodb = _dynamodb_resource()
    table = dynamodb.Table(table_name)

    records = event.get("Records", [])
    responses = []

    for record in records:
        payload = json.loads(record["body"])
        item = _build_item(payload)
        table.put_item(Item=item)
        responses.append(
            {
                "request_id": item["request_id"],
                "tenant_id": item["tenant_id"],
                "account_id": item["account_id"],
                "deployment_group_status": item["deployment_group_status"],
                "service_enaablement_status": item["service_enaablement_status"],
            }
        )

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": len(responses), "items": responses}),
    }
