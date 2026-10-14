---
description: Deploy and verify the LocalStack Ops demo while preserving useful failure evidence.
always: true
---

# LocalStack Ops deploy-and-test workflow

A cron run starts in an empty workspace. Do not assume its current directory is
the demo repository.

Scheduled runs ask the user to approve every shell command and MCP call, and an
unanswered request expires. Keep the run to the steps below: do not add extra
shell commands such as `lstk status`, and never use the legacy `localstack` CLI.

1. Resolve the installed app path:

   ```bash
   app_home="${KIROCREW_HOME:-$HOME/.kiro/crew}/apps/localstack-ops"
   source_dir="$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["source"])' "$app_home/installed.json")"
   repo_root="$(dirname "$source_dir")"
   ```

2. Verify `"$repo_root/scripts/deploy-and-smoke.sh"` exists. Do not inspect or print authentication tokens.
3. Make sure LocalStack is running with the LocalStack MCP `localstack-management` tool:
   - Call it with `action: "status"`.
   - If LocalStack is not running, call it with `action: "start"` and `envVars: {"ENFORCE_IAM": "1"}` so the Lambda role's IAM policy is enforced.
   - If the tool is unavailable or the start fails (for example, `Auth Token Required` when the MCP server has no `LOCALSTACK_AUTH_TOKEN`), continue: the script in the next step starts LocalStack with `lstk` instead. Mention which path started it in your summary.
4. Run `"$repo_root/scripts/deploy-and-smoke.sh"`. It uses `lstk` for Terraform and AWS requests, and only starts LocalStack itself if it is still not running.
5. If the deploy or smoke test fails, diagnose it with the LocalStack MCP tools before recording the result:
   - `localstack-logs-analysis` for errors from the `localstack-ops-processor` Lambda and any `AccessDenied` entries.
   - `localstack-iam-policy-analyzer` to identify the denied action and the policy that should allow it.
6. Record every outcome with the installed app's recorder:

   ```bash
   python3 "$app_home/backend/record_run.py" \
     --status passed \
     --summary "Smoke test completed" \
     --diagnostic ""
   ```

   For a non-zero deploy or smoke-test result, use `failed` and include the concrete MCP diagnostic evidence from step 5. Do not fabricate an MCP result.
7. Report the outcome concisely. A failed run with useful evidence is a successful demo outcome.

## Failure path to demonstrate

For the article, introduce one small, reversible defect only after capturing a passing run. Suggested defect: remove the `dynamodb:PutItem` statement from the Lambda policy in `infra/main.tf`, let the next run reapply it, and capture the failed smoke test and its IAM diagnosis. Restore the statement after collecting the evidence.
