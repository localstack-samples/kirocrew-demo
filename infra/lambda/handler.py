"""Record each smoke-test object that LocalStack delivers through S3 to Lambda."""

import json
import os
from datetime import UTC, datetime
from urllib.parse import unquote_plus

import boto3


def handler(event, _context):
    table = boto3.resource("dynamodb").Table(os.environ["RUNS_TABLE"])
    recorded = []

    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = unquote_plus(record["s3"]["object"]["key"])
        payload = boto3.client("s3").get_object(Bucket=bucket, Key=key)["Body"].read()
        run = json.loads(payload)
        run_id = run["run_id"]
        table.put_item(
            Item={
                "run_id": run_id,
                "status": "passed",
                "recorded_at": datetime.now(UTC).isoformat(),
                "source_key": key,
            }
        )
        recorded.append(run_id)

    return {"recorded": recorded}
