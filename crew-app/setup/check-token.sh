#!/usr/bin/env bash
# Runs as the app's onEnable hook, from the installed app directory. A non-zero
# exit makes KiroCrew roll the enable back, so the app cannot run without the
# token its LocalStack MCP server needs.
if [[ ! -s data/localstack-auth-token ]]; then
  echo "LocalStack Ops needs your LocalStack auth token before it can be enabled."
  echo "The LocalStack MCP server, which the agent uses to inspect LocalStack and diagnose failures, requires it."
  echo "From the demo repository, run: scripts/save-localstack-token.sh"
  echo "Then enable LocalStack Ops again."
  exit 1
fi
