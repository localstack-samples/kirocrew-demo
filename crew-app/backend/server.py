"""Small, dependency-free run-history API for the LocalStack Ops Crew App.

The scheduled agent appends results with record_run.py; this server only reads
them for the dashboard.
"""

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

from kiro_crew.apps.proxy_auth import verify_proxy_request

APP_NAME = "localstack-ops"
DATA_FILE = Path(os.environ["KIROCREW_HOME"]) / "apps" / APP_NAME / "data" / "runs.json"


def read_runs():
    if not DATA_FILE.exists():
        return []
    return json.loads(DATA_FILE.read_text(encoding="utf-8"))


class Handler(BaseHTTPRequestHandler):
    def _json(self, status, value):
        body = json.dumps(value).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _authorized(self, body):
        return verify_proxy_request(
            self.headers.get("X-KiroCrew-Proxy", ""),
            method=self.command,
            target=self.path,
            body=body,
        )

    def do_GET(self):
        if self.path == "/health":
            self._json(200, {"status": "ok"})
            return
        if not self._authorized(b""):
            self._json(401, {"error": "gateway proxy authentication required"})
            return
        if self.path.rstrip("/") == "/api/history":
            self._json(200, {"runs": read_runs()[-20:][::-1]})
            return
        self._json(404, {"error": "not found"})

    def log_message(self, format, *args):
        # KiroCrew captures stderr in data/logs/backend.log; one line per request
        # makes it possible to see whether the dashboard reached the backend.
        sys.stderr.write(f"{self.command} {self.path} -> {args[1] if len(args) > 1 else ''}\n")
        sys.stderr.flush()


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", int(os.environ["PORT"])), Handler).serve_forever()
