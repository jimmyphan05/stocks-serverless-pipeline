import json
import logging
import time
from typing import Optional

import boto3
import requests

logger = logging.getLogger()

secrets_client = boto3.client("secretsmanager")

def get_api_key(secret_arn: str) -> str:
    response = secrets_client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response["SecretString"])
    return secret["api_key"]


def find_best_mover(watchlist: list, trade_date: str, api_key: str) -> tuple:
    #Return (ticker, percent_change, open_price, close_price) for the biggest mover, or (None, None, None, None)
    best_ticker = None
    best_pct_change = None
    best_open = None
    best_close = None

    for ticker in watchlist:
        open_close_prices = fetch_daily_open_close(ticker, trade_date, api_key)
        if open_close_prices is None:
            continue

        open_price = open_close_prices["open"]
        close_price = open_close_prices["close"]

        if open_price == 0:
            logger.warning("Open price is 0 for %s, skipping", ticker)
            continue

        percent_change = ((close_price - open_price) / open_price) * 100
        logger.info("%s: open=%.2f close=%.2f percent_change=%.4f%%", ticker, open_price, close_price, percent_change)

        if best_pct_change is None or (abs(percent_change) > abs(best_pct_change)):
            best_ticker = ticker
            best_pct_change = percent_change
            best_open = open_price
            best_close = close_price

    return best_ticker, best_pct_change, best_open, best_close


def fetch_daily_open_close(ticker: str, trade_date: str, api_key: str, retries: int = 2) -> Optional[dict]:
    # Fetch open/close prices for a ticker from the massive API with retries on rate limit
    url = f"https://api.massive.com/v1/open-close/{ticker}/{trade_date}"
    params = {"adjusted": "true", "apiKey": api_key}

    for attempt in range(retries):
        try:
            response = requests.get(url, params=params, timeout=10)

            # RATE LIMITED: Massive API allows for 5 request per minute so if rate limited, wait 60 seconds (+1 sec for buffer) before retrying
            if response.status_code == 429:
                wait = 61
                logger.warning("Rate limited on %s, retrying in %ds", ticker, wait)
                time.sleep(wait)
                continue

            # Weekend or holiday, no data for this date
            if response.status_code == 404:
                logger.warning("Market closed due to holiday or weekend, no data found for %s on %s", ticker, trade_date)
                break

            response.raise_for_status()
            data = response.json()

            return {"open": data["open"], "close": data["close"]}

        except requests.RequestException as exc:
            logger.error("Request failed for %s (attempt %d): %s", ticker, attempt + 1, exc)

    return None