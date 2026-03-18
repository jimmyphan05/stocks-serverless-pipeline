import json
import logging
import time

import boto3
import requests

logger = logging.getLogger()

secrets_client = boto3.client("secretsmanager")


def get_api_key(secret_arn: str) -> str:
    response = secrets_client.get_secret_value(SecretId=secret_arn)
    secret = json.loads(response["SecretString"])
    return secret["api_key"]


def fetch_daily_bar(ticker: str, trade_date: str, api_key: str, retries: int = 3) -> dict | None:
    """Fetch open/close bar for a ticker from the Massive API with retry on rate limit."""
    url = f"https://api.massiveapi.com/v1/aggs/ticker/{ticker}/range/1/day/{trade_date}/{trade_date}"
    headers = {"Authorization": f"Bearer {api_key}"}

    for attempt in range(retries):
        try:
            response = requests.get(url, headers=headers, timeout=10)

            if response.status_code == 429:
                wait = 2 ** attempt
                logger.warning("Rate limited on %s, retrying in %ds", ticker, wait)
                time.sleep(wait)
                continue

            response.raise_for_status()
            data = response.json()

            results = data.get("results", [])
            if not results:
                logger.warning("No data returned for %s on %s", ticker, trade_date)
                return None

            bar = results[0]
            return {"open": bar["o"], "close": bar["c"]}

        except requests.RequestException as exc:
            logger.error("Request failed for %s (attempt %d): %s", ticker, attempt + 1, exc)
            if attempt < retries - 1:
                time.sleep(2 ** attempt)

    return None