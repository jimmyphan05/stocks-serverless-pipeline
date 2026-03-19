import json
import logging
import os
from datetime import date, datetime, timedelta, timezone

import boto3
from botocore.exceptions import ClientError

from utils import find_best_mover, get_api_key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

WATCHLIST = os.environ["WATCHLIST"].split(",")
DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
SECRET_ARN = os.environ["SECRET_ARN"]

dynamodb = boto3.resource("dynamodb")



def ingestion_lambda_handler(event, context):
    try:
        api_key = get_api_key(SECRET_ARN)
    except ClientError as exc:
        logger.error("Failed to retrieve API key from Secrets Manager: %s", exc)
        return {"statusCode": 500, "body": json.dumps({"message": "Failed to retrieve API key"})}

    trade_date = (date.today() - timedelta(days=1)).isoformat()
    logger.info("Processing trade date: %s", trade_date)

    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    best_ticker, best_pct_change, best_open, best_close = find_best_mover(WATCHLIST, trade_date, api_key)

    if best_ticker is None:
        logger.error("No valid data found for %s, ", trade_date)
        return {"statusCode": 404, "body": json.dumps({"message": f"Market closed for holiday or weekend, no valid stock data found for {trade_date}"})}

    ttl = int((datetime.now(timezone.utc) + timedelta(days=30)).timestamp())
    table.put_item(
        Item={
            "date": trade_date,
            "ticker": best_ticker,
            "percent_change": str(round(best_pct_change, 4)),
            "open_price": str(round(best_open, 2)),
            "close_price": str(round(best_close, 2)),
            "ttl": ttl,
        }
    )
    logger.info("Wrote best mover: %s %s %.4f%% open=%.2f close=%.2f", trade_date, best_ticker, best_pct_change, best_open, best_close)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Ingestion complete",
            "date": trade_date,
            "ticker": best_ticker,
            "percent_change": round(best_pct_change, 4),
            "open_price": round(best_open, 2),
            "close_price": round(best_close, 2),
        }),
    }