# Stocks Serverless Pipeline

A fully automated, serverless stock tracking dashboard built on AWS. Every day at 4:10pm ET (10 minutes after market closes), a Lambda function fetches daily open/close data for a watchlist of tech stocks, calculates which one moved the most (highest absolute percent change), and stores the result in DynamoDB. A React frontend hosted on S3 displays the last 7 days of top movers (excluding weekends and holidays) via a REST API.

**Watchlist:** AAPL, MSFT, GOOGL, AMZN, TSLA, NVDA

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with credentials (`aws configure`)
- A free [Massive API](https://massive.com) account and API key
- Python 3.10+ (for rebuilding the Lambda zip if needed)

## Deployment

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd stocks-serverless-pipeline
```

### 2. Configure secrets

Create `infrastructure/environments/prod/terraform.tfvars` (this file is gitignored):

```hcl
massive_api_key      = "your-massive-api-key"
frontend_bucket_name = "your-globally-unique-bucket-name"
```

### 3. Deploy infrastructure

```bash
cd infrastructure/environments/prod
terraform init
terraform apply
```

Note the outputs — you will need `api_endpoint` and `frontend_bucket_name` in the next steps.

### 4. Build and deploy the frontend

Create `frontend/.env` (this file is gitignored):

```bash
echo "VITE_API_URL=https://<your-api-id>.execute-api.us-west-1.amazonaws.com" > frontend/.env
```

Use the `api_endpoint` value from `terraform output api_endpoint`.

Then build and upload:

```bash
cd frontend
npm install
npm run build
aws s3 sync dist/ s3://<your-bucket-name> --delete
```

### 5. View the live site

```bash
cd infrastructure/environments/prod
terraform output frontend_url
```

Open that URL in your browser.

---

## How It Works

### Ingestion Lambda (`backend/ingestion_lambda/`)

- Triggered daily by EventBridge at 4:10 PM ET (after market close)
- Fetches open/close prices for each watchlist ticker from the Massive API
- Calculates `((close - open) / open) * 100` for each ticker
- Stores the biggest mover in DynamoDB with a 30-day TTL
- Handles rate limiting (5 req/min on free tier) with a 61-second retry wait

### Retrieval Lambda (`backend/retrieval_lambda/`)

- Triggered by `GET /movers` on API Gateway
- Scans DynamoDB, sorts by date descending, returns the latest 7 records
- API Gateway throttled to 10 req/sec to prevent abuse

### Frontend (`frontend/`)

- React + Bootstrap, built with Vite
- Displays each day's top mover as a color-coded card (green = gain, red = loss)
- Hosted as a static website on S3

---

## Rebuilding Lambda Zips

If you modify `backend/ingestion_lambda/ingestion.py` or `utils.py`:

```bash
cd backend/ingestion_lambda
zip -r lambda.zip ingestion.py utils.py requests/ urllib3/ certifi/ charset_normalizer/ idna/
cd ../../infrastructure/environments/prod
terraform apply
```

If you modify `backend/retrieval_lambda/retrieval.py`:

```bash
cd backend/retrieval_lambda
zip lambda.zip retrieval.py
cd ../../infrastructure/environments/prod
terraform apply
```

---

## Manually Invoking the Ingestion Lambda

To trigger a run outside of the scheduled cron:

```bash
aws lambda invoke \
  --function-name stock-ingestion-prod \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  --cli-read-timeout 180 \
  response.json && cat response.json
```

---

## Security

- API keys are stored in AWS Secrets Manager, never in code or environment variables
- IAM roles follow least privilege — ingestion Lambda can only write to DynamoDB, retrieval Lambda can only read
- No secrets are committed to the repository (`.gitignore` covers `.env`, `*.tfvars`, `*.tfstate`)
- API Gateway is throttled to prevent abuse

---
