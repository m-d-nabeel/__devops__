import json
import os
import uuid
import boto3


def lambda_handler(event, context):
    target_bucket = os.environ.get("TARGET_BUCKET", "undefined")

    response = {
        "statusCode": 200,
        "body": json.dumps(
            {
                "status": "ok",
                "message": f"Hello from Lambda! Target bucket is {target_bucket}",
                "input": event,
                "context": str(context),
                "length": len(event.get("Records", [])),
            }
        ),
    }

    # Use LocalStack endpoint if provided via env var
    endpoint_url = os.environ.get("AWS_ENDPOINT_URL")
    region_name = os.environ.get("AWS_REGION", "us-east-1")
    if endpoint_url:
        dynamodb = boto3.resource(
            "dynamodb", endpoint_url=endpoint_url, region_name=region_name
        )
    else:
        dynamodb = boto3.resource("dynamodb", region_name=region_name)

    table_name = "my-dynamodb-table"
    my_dynamodb_table = dynamodb.Table(table_name)

    my_dynamodb_table.put_item(Item={"id": str(uuid.uuid4()), "data": response})

    return response
