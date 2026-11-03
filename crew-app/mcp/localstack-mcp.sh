#!/usr/bin/env bash
set -euo pipefail

# Start the LocalStack MCP server with the auth token saved for this app.
# KiroCrew passes an app MCP server's env values through literally, so the
# token cannot be referenced from the agent file itself.
token_file="${KIROCREW_HOME:-$HOME/.kiro/crew}/apps/localstack-ops/data/localstack-auth-token"
if [[ ! -s "$token_file" ]]; then
  echo "LocalStack Ops: no LocalStack auth token at $token_file; save it as described in the demo README" >&2
  exit 1
fi

LOCALSTACK_AUTH_TOKEN="$(tr -d '[:space:]' < "$token_file")"
export LOCALSTACK_AUTH_TOKEN
exec npx -y @localstack/localstack-mcp-server
