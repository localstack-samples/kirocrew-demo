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
lstk terraform -chdir=infra init
lstk terraform -chdir=infra apply -auto-approve
