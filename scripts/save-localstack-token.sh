#!/usr/bin/env bash
set -euo pipefail

# Save the LocalStack auth token where the LocalStack Ops app's MCP server reads
# it. The token is read without echoing it or adding it to shell history.
app_data="${KIROCREW_HOME:-$HOME/.kiro/crew}/apps/localstack-ops/data"
token_file="$app_data/localstack-auth-token"

read -rsp "LocalStack auth token (https://app.localstack.cloud/workspace/auth-tokens): " token
echo
token="$(printf '%s' "$token" | tr -d '[:space:]')"
if [[ -z "$token" ]]; then
  echo "No token entered; nothing was saved." >&2
  exit 1
fi

mkdir -p "$app_data"
(umask 077 && printf '%s\n' "$token" > "$token_file")
echo "Saved to $token_file"
