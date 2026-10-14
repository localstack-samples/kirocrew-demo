#!/usr/bin/env python3
"""Record a LocalStack Ops result from the scheduled agent.

The app backend and the scheduled agent share this deliberately small, local
data contract.  It avoids asking an agent to manufacture the dashboard's
proxy-authentication header while retaining an append-only run history.
"""

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path


APP_NAME = "localstack-ops"


def data_file() -> Path:
    crew_home = Path(os.environ.get("KIROCREW_HOME", Path.home() / ".kiro" / "crew"))
    return crew_home / "apps" / APP_NAME / "data" / "runs.json"


def main() -> None:
    parser = argparse.ArgumentParser(description="Record a LocalStack Ops workflow result")
    parser.add_argument("--status", choices=("passed", "failed"), required=True)
    parser.add_argument("--summary", required=True)
    parser.add_argument("--diagnostic", default="")
    args = parser.parse_args()

    path = data_file()
    path.parent.mkdir(parents=True, exist_ok=True)
    runs = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
    run = {
        "status": args.status,
        "summary": args.summary,
        "diagnostic": args.diagnostic,
        "recorded_at": datetime.now(timezone.utc).isoformat(),
    }
    runs.append(run)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(runs[-50:], indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)
    print(json.dumps(run))


if __name__ == "__main__":
    main()
