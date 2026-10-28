#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Enforce IAM so the Lambda role's policy matters, as it would on AWS. lstk
# forwards LOCALSTACK_-prefixed variables to the emulator, but only when it
# starts it: an emulator that is already running keeps its original settings.
export LOCALSTACK_ENFORCE_IAM=1

# lstk owns emulator lifecycle and its authenticated local profile. No token is
# read from, exported by, or stored in this repository.
if ! lstk status --no-resources >/dev/null 2>&1; then
  lstk start --type aws --timeout 60s --non-interactive
fi

# An emulator started elsewhere without IAM enforcement accepts every call, so a
# broken policy would still pass. Restart it with enforcement; this resets any
# state it holds, which is why an already-enforcing emulator is left alone.
iam_enforced() {
  local container
  container="$(lstk status --json --no-resources | python3 -c 'import json, sys; print(json.load(sys.stdin)["data"]["emulators"][0]["name"])')"
  docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' \
    | grep -qE '^(LOCALSTACK_)?ENFORCE_IAM=1$'
}
if ! iam_enforced; then
  echo "LocalStack is running without IAM enforcement; restarting it with ENFORCE_IAM=1 (its current state will be reset)."
  lstk stop --non-interactive
  lstk start --type aws --timeout 60s --non-interactive
  if ! iam_enforced; then
    echo "FAIL: LocalStack restarted but IAM enforcement is still off, so IAM policy errors cannot be detected." >&2
    exit 1
  fi
fi

lstk terraform -chdir=infra init
lstk terraform -chdir=infra apply -auto-approve
