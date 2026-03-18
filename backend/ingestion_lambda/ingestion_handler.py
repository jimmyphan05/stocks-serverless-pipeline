import json
import logging
import os
from datetime import date, timedelta

import boto3
from botocore.exceptions import ClientError

from utils import fetch_daily_bar, get_api_key

logger = logging.getLogger()
logger.setLevel(logging.INFO)

WATCHLIST = os.environ["WATCHLIST"].split(",")
DYNAMODB_TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
SECRET_ARN = os.environ["SECRET_ARN"]

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):
    # Use previous trading day (Lambda runs after close, so today's data is available,
    # but we target the most recent completed trading day)
    trade_date = (date.today() - timedelta(days=1)).isoformat()
    logger.info("Running ingestion for date: %s", trade_date)

    try:
        api_key = get_api_key(SECRET_ARN)
    except ClientError as exc:
        logger.error("Failed to retrieve API key from Secrets Manager: %s", exc)
        raise

    best_ticker = None
    best_pct_change = None
    best_close = None

    for ticker in WATCHLIST:
        bar = fetch_daily_bar(ticker, trade_date, api_key)
        if bar is None:
            continue

        open_price = bar["open"]
        close_price = bar["close"]

        if open_price == 0:
            logger.warning("Open price is 0 for %s, skipping", ticker)
            continue

        pct_change = ((close_price - open_price) / open_price) * 100
        logger.info("%s: open=%.2f close=%.2f pct_change=%.4f%%", ticker, open_price, close_price, pct_change)

        if best_pct_change is None or abs(pct_change) > abs(best_pct_change):
            best_ticker = ticker
            best_pct_change = pct_change
            best_close = close_price

    if best_ticker is None:
        logger.error("No valid stock data retrieved for %s. Nothing written to DynamoDB.", trade_date)
        return {"statusCode": 500, "body": "No stock data available"}

    logger.info("Winner: %s with %.4f%% change", best_ticker, best_pct_change)

    table = dynamodb.Table(DYNAMODB_TABLE_NAME)
    table.put_item(
        Item={
            "date": trade_date,
            "ticker": best_ticker,
            "percent_change": str(round(best_pct_change, 4)),
            "close_price": str(round(best_close, 2)),
        }
    )
    logger.info("Wrote result to DynamoDB: %s %s %.4f%%", trade_date, best_ticker, best_pct_change)

    return {"statusCode": 200, "body": json.dumps({"date": trade_date, "ticker": best_ticker, "percent_change": best_pct_change})}