import json
import logging
import os

import boto3
from boto3.dynamodb.conditions import Attr
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
MOVERS_LIMIT = 7

dynamodb = boto3.resource("dynamodb")


def retrieval_lambda_handler(event, context):
    table = dynamodb.Table(DYNAMODB_TABLE_NAME)

    try:
        # Scan all items
        response = table.scan(
            FilterExpression=Attr("date").exists()
        )
        items = response.get("Items", [])
    except ClientError as exc:
        logger.error("DynamoDB scan failed: %s", exc)
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Failed to retrieve data"}),
        }

    # Sort by date descending, take latest 7, strip internal fields
    items.sort(key=lambda x: x["date"], reverse=True)
    top_movers = [
        {k: v for k, v in item.items() if k != "ttl"}
        for item in items[:MOVERS_LIMIT]
    ]

    logger.info("Returning %d movers", len(top_movers))

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"movers": top_movers}),
    }