#!/usr/bin/env bash
set -euo pipefail

bucket="localstack-ops-input"
table="localstack-ops-runs"
run_id="smoke-$(date -u +%Y%m%dT%H%M%SZ)"
payload="$(mktemp)"
trap 'rm -f "$payload"' EXIT

export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

printf '{"run_id":"%s"}\n' "$run_id" > "$payload"
lstk aws s3api put-object \
  --bucket "$bucket" --key "health/${run_id}.json" --body "$payload" >/dev/null

for _ in $(seq 1 30); do
  item="$(lstk aws dynamodb get-item \
    --table-name "$table" --key "{\"run_id\":{\"S\":\"${run_id}\"}}")"
  if printf '%s' "$item" | grep -q '"status"'; then
    printf 'PASS: %s completed the S3 → Lambda → DynamoDB path\n' "$run_id"
    exit 0
  fi
  sleep 1
done

echo "FAIL: ${run_id} was not recorded in DynamoDB within 30 seconds" >&2
exit 1
