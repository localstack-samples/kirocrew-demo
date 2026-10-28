# LocalStack Ops in KiroCrew Desktop

This intentionally small demo lets you use KiroCrew Desktop to run and observe a local-cloud check. The **LocalStack Ops** app asks its agent to inspect LocalStack, deploy a Terraform S3 → Lambda → DynamoDB flow, run a smoke test, and record the real outcome in the dashboard.

## What you will see

![A KiroCrew Desktop schedule runs the LocalStack Ops agent, which deploys and smoke-tests an S3 to Lambda to DynamoDB flow in LocalStack, inspects it through the @localstack MCP server, and records each result in the dashboard.](docs/architecture.svg)

## Local-only AWS environment

Every AWS-facing component in this demo runs on your computer. LocalStack emulates the AWS APIs used by Terraform; it does not contact a real AWS account. KiroCrew still uses whichever Kiro CLI model provider you have configured, so follow KiroCrew's normal guidance not to place sensitive data in prompts. The optional Run on AWS/EC2 option in KiroCrew is for hosting KiroCrew itself continuously and is outside the scope of this tutorial.

| Component | Where it runs |
| --- | --- |
| KiroCrew Desktop, dashboard, and schedule | Your computer |
| S3, Lambda, and DynamoDB APIs | LocalStack's Docker container on your computer |
| Terraform deployment and smoke test | This project, through `lstk` |

## Before you start

Here's what you'll need:

* Docker Desktop (or another Docker engine)
* Terraform
* AWS CLI v2 (`lstk aws` runs your installed AWS CLI; on Apple silicon, install the native arm64 build)
* Python 3 as `python3` (macOS's built-in version is fine); the app uses it to record each run
* LocalStack's [`lstk`](https://docs.localstack.cloud/aws/tooling/lstk/) CLI
* [KiroCrew Desktop](https://kiro.dev/crew/)
* The [LocalStack Kiro Power](https://github.com/kirodotdev/powers/tree/main/localstack) installed and enabled in Kiro so that KiroCrew can use `@localstack`.

If you haven't authenticated LocalStack's CLI before, this is the only command-line sign-in step:

```bash
lstk login
```

Complete the normal browser sign-in. The credentials are stored in your system keychain.

This repository includes the prebuilt LocalStack Ops panel in `crew-app/ui/dist/`, so you don't need to build anything. You do need Node.js (for `npx`), because the LocalStack MCP server runs through it—the LocalStack Power already requires it.

## Use the app in KiroCrew Desktop

### 1. Confirm the local connection

Open KiroCrew Desktop. On a new installation, complete its initial sign-in/setup flow and decline the optional AWS/EC2 hosting path.

Open **Agent Capabilities → MCP Connections** and confirm that a `localstack` connection is present and enabled. If it's missing, enable the LocalStack Power in Kiro and complete the KiroCrew setup flow again before continuing.

This connection is for your own KiroCrew conversations. KiroCrew doesn't share it with app agents, so the LocalStack Ops agent declares its own LocalStack MCP server in `crew-app/agents/localstack-ops-agent.json`.

### 2. Install the LocalStack Ops app from this folder

1. In the sidebar, open **Apps** and choose **Discover**.
2. Select **Sources** (the gear control in the Discover header).
3. Choose the option to install a local directory.
4. Select the `crew-app` folder inside your clone of this repository—for example, `<path-to-clone>/crew-app`. Don't select the repository root: the app's manifest, `app.json`, is in `crew-app`.

5. Review the app details and install it.

KiroCrew copies the app into its local app store. It is initially disabled, and Library hides disabled apps by default. If you do not see **LocalStack Ops**, select **Show _n_ disabled apps** in Library first. If it is already present, do not install it again; continue with the existing app.

When this repository changes, refresh the installed copy from the Desktop app: in **Apps → Library**, open **LocalStack Ops** and select **Sync** ("Sync app from its source directory"). KiroCrew copies the updated `crew-app` folder, re-registers the app's agent and skill, and restarts its backend. Recorded runs are kept. The scheduled job keeps a persistent agent session, though, and a session that's already running keeps the agent definition it started with. After a sync, quit KiroCrew Desktop completely (**Cmd+Q**, not just closing the window) and reopen it before triggering the job, so the next run starts a fresh session with the updated agent. If you only changed the dashboard, use **View → Force Reload** (**Cmd+Shift+R**) instead: KiroCrew keeps an app page's code loaded until the window reloads, so a sync alone leaves the old dashboard running.

### 3. Review and enable it

1. In **Apps → Library**, select **Show _n_ disabled apps** if necessary, then open **LocalStack Ops**.
2. Read the app's description and review this repository's `crew-app/` directory if you have not already.
3. Select **Enable**.
4. When KiroCrew asks for third-party-app consent, approve **LocalStack Ops** only.

Enabling registers the app's agent, its `@localstack` access, its backend, its dashboard page, and the scheduled check.

### 4. Trigger the first run and inspect the result

1. Open **Schedule** from the sidebar and find `localstack-ops-check`.
2. Use the job's immediate-run action to start it now. The Schedule execution view shows its progress.
3. **Watch for approval requests—they're easy to miss.** A scheduled job has no conversation to ask in, so KiroCrew doesn't show its requests in the Schedule view. It plays a notification sound, and the request itself waits in the alerts panel: select the small alert icon to open it, then approve the **Approval needed** entry. Keep that panel open for the whole first run. Expect a request for each of these:
   - the LocalStack MCP status call (and a start call, if LocalStack isn't running),
   - the command that runs `scripts/deploy-and-smoke.sh`,
   - the command that records the result.

   Reading files is approved automatically.
4. Open **LocalStack Ops** in the sidebar to see the recorded outcome.

An unanswered request expires after about three minutes and the agent's action is rejected, so stay with the first run. To let later scheduled runs proceed without you, add `"cron"` to `hooks.auto_approve_sources` in `~/.kiro/crew/config.json`. That opt-in applies to **every** scheduled job in KiroCrew, not only this one, so decide whether you want it before enabling it.

On a successful run, the dashboard shows **Passed** and a run record. The agent resolves the original demo source folder before it runs, checks LocalStack through the LocalStack Power, starts it with IAM enforcement if necessary (through the Power when it has an auth token, otherwise with `lstk`), applies Terraform through `lstk`, uploads a unique object, and waits for the S3 → Lambda → DynamoDB result. If it fails, the app records the concrete failure and any LocalStack MCP diagnostics instead of claiming success.

The job is installed with its 15-minute schedule switched off, so it only runs when you start it. When you're ready to demonstrate recurring automation, enable it in **Schedule**—and either add `"cron"` to `hooks.auto_approve_sources` or expect a new round of approval requests every 15 minutes. Disable it again when you're done. Cancelling a single run doesn't stop the schedule.

## What to try next: catch an IAM bug locally

LocalStack only evaluates IAM policies when it's started with `ENFORCE_IAM=1`. The agent passes `ENFORCE_IAM=1` when it starts LocalStack through the Power, and `scripts/deploy.sh` sets `LOCALSTACK_ENFORCE_IAM=1` when it has to start the emulator itself, so the Lambda's role behaves as it would on AWS. That setting only applies at startup, so if LocalStack is already running without it—for example, started by another project—`scripts/deploy.sh` restarts it with enforcement. The restart resets everything in that LocalStack instance, including other projects' resources; a LocalStack that already enforces IAM is left alone.

After recording one passing run:

1. Open the LocalStack Ops page and note the passing baseline.
2. In `infra/main.tf`, delete the statement that allows `dynamodb:PutItem` from `aws_iam_role_policy.processor`.
3. Trigger `localstack-ops-check` again. Terraform applies the narrower policy, the Lambda is denied when it writes to DynamoDB, and the smoke test times out. The agent uses the LocalStack MCP to find the denied action and records a **Failed** run with that evidence.
4. Restore the statement, trigger the job once more, and confirm the dashboard returns to **Passed**.

## When a run doesn't finish

A scheduled run fails quietly: the Schedule view can show a run as in progress, or as cancelled or failed, with no explanation, and the dashboard simply has no new record. These are the places to look, in order.

1. **The alerts panel.** Select the small alert icon and look for a pending **Approval needed** request. This is the most common cause: the agent is waiting for you, and the only other sign is a notification sound.
2. **Schedule → `localstack-ops-check` → execution view.** The run's status and the agent's final summary. `Cancelled by user` or `process not running` means the run never reached the recorder.
3. **KiroCrew's audit log.** Every tool call, approval and denial is recorded. This shows which command was waiting and whether its approval expired:

   ```bash
   grep -E 'approval_decision|not_auto_approved|Running:' ~/.kiro/crew/security_events.jsonl | tail -20
   ```

4. **KiroCrew's gateway log.** App and MCP problems appear here. For example, `unresolved=@localstack` means the agent did not receive the LocalStack MCP server:

   ```bash
   grep -E 'localstack-ops|unresolved=' ~/.kiro/crew/gateway.log | tail -20
   ```

5. **The scripts themselves.** Run `scripts/deploy-and-smoke.sh` in a terminal. If it fails there, the problem is in your local setup (Docker, `lstk`, AWS CLI, Terraform), not in KiroCrew.

## Troubleshooting

- **No `localstack` connection appears in Agent Capabilities:** enable the LocalStack Power/MCP server in Kiro, then repeat the KiroCrew setup flow. Do not enable LocalStack Ops until it appears.
- **There is no `localstack-ops-check` job:** confirm that LocalStack Ops is enabled in **Apps → Library**. Disabling an app removes its cron jobs.
- **The first run cannot reach LocalStack:** start Docker Desktop, then run `lstk login` in KiroCrew Desktop's Terminal tab and retry the job.
- **LocalStack Ops is already installed but not visible:** in **Apps → Library**, select **Show _n_ disabled apps**, then open it instead of installing a second copy.
- **Installing fails with `cannot install while app.json has no readable app identity`:** you selected a folder without an `app.json`, usually the repository root. Install the `crew-app` folder instead.
- **A run stays in progress and nothing is recorded:** the agent is waiting for a tool approval. Approve it from KiroCrew's alerts panel (the small alert icon); if it expired, cancel the run and trigger the job again. See [When a run doesn't finish](#when-a-run-doesnt-finish).
- **The agent still behaves like the previous version after a Sync:** the job reused a session that was already running. Cancel the run, quit KiroCrew Desktop with **Cmd+Q**, reopen it,, and trigger it again.
- **The dashboard stays on Pending or "No runs recorded" after runs pass:** the window is still running an older copy of the dashboard. Press **Cmd+Shift+R** (**View → Force Reload**). To confirm, open **View → Toggle Developer Tools**; an `[app-sdk] App "localstack-ops" not permitted to access /api/apps/localstack-ops/history` error in the Console means the old dashboard code is still loaded.
- **Approval requests keep arriving after you stop a run:** cancelling a run doesn't disable the schedule, and KiroCrew treats the cancelled run's stopped agent as a crash and retries it once. Disable `localstack-ops-check` in **Schedule**, then let any remaining requests expire.
- **The run summary says LocalStack was started with `lstk` rather than the Power:** the Power's start needs a `LOCALSTACK_AUTH_TOKEN`, and the app's agent runs its own LocalStack MCP server without one. That's expected; the agent still uses the Power to inspect LocalStack and diagnose failures.
- **The dashboard shows `Could not load run history`:** make sure LocalStack Ops is enabled and trusted, then reopen the page. KiroCrew only starts a third-party app's backend once the app is trusted.
- **The smoke test fails with `bad CPU type in executable`:** your AWS CLI is an Intel build on an Apple silicon Mac without Rosetta (a macOS update can remove it). Install the native arm64 AWS CLI v2 (for example, `brew install awscli`) or reinstall Rosetta with `softwareupdate --install-rosetta --agree-to-license`, then retry.
- **Other LocalStack work disappeared after a run:** LocalStack was running without IAM enforcement, so `scripts/deploy.sh` restarted it with `ENFORCE_IAM=1`, which resets its state. To avoid this, start LocalStack with enforcement for all your work (for example, set `ENFORCE_IAM = "1"` in an env profile in your `lstk` config).
- **A run fails with `LocalStack restarted but IAM enforcement is still off`:** the restart didn't pick up the setting. Check that nothing else starts LocalStack at the same moment, run `lstk stop`, and trigger the job again.
- **You see warnings about stored defaults or a retired STT provider:** those are unrelated KiroCrew configuration-migration notices. Review them separately in Settings; they do not indicate a LocalStack failure.

## For contributors

The desktop tutorial uses the checked-in `crew-app/ui/dist/index.mjs` bundle. Rebuild it only when editing the React source:

```bash
(cd crew-app/ui && npm install --legacy-peer-deps --no-audit --no-fund && npm run build)
```

The Terraform and test scripts remain available for development and debugging:

```bash
scripts/deploy-and-smoke.sh
```

The app intentionally uses `lstk`; it does not use the legacy `localstack` CLI.
