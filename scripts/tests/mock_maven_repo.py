#!/usr/bin/env python3
"""
Minimal mock Maven repository used by the fetch_artifacts source tests.

It serves artifact files from a content directory using the standard Maven GAV
layout and enforces Basic authentication when credentials are configured. Every
received Authorization header is appended to a log file so tests can assert which
source's credentials were actually sent.

Configuration (environment variables):
  MOCK_PORT      port to listen on (required)
  MOCK_ROOT      directory whose files are served (required)
  MOCK_USER      required Basic auth username (empty => anonymous access)
  MOCK_PASS      required Basic auth password (empty => anonymous access)
  MOCK_LOG       file to append received Authorization headers to (optional)
"""

import base64
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MOCK_ROOT = os.environ["MOCK_ROOT"]
MOCK_USER = os.environ.get("MOCK_USER", "")
MOCK_PASS = os.environ.get("MOCK_PASS", "")
MOCK_LOG = os.environ.get("MOCK_LOG", "")

EXPECTED_AUTH = None
if MOCK_USER and MOCK_PASS:
    token = base64.b64encode(f"{MOCK_USER}:{MOCK_PASS}".encode("utf-8")).decode("ascii")
    EXPECTED_AUTH = f"Basic {token}"


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        auth = self.headers.get("Authorization", "")
        if MOCK_LOG:
            with open(MOCK_LOG, "a", encoding="utf-8") as log_file:
                log_file.write(f"{self.path} {auth}\n")

        # A path explicitly marked forbidden always returns 403.
        if "forbidden" in self.path:
            self.send_response(403)
            self.end_headers()
            return

        # Enforce authentication when credentials are configured.
        if EXPECTED_AUTH is not None and auth != EXPECTED_AUTH:
            self.send_response(401)
            self.end_headers()
            return

        file_path = os.path.normpath(os.path.join(MOCK_ROOT, self.path.lstrip("/")))
        if not file_path.startswith(os.path.abspath(MOCK_ROOT)) or not os.path.isfile(file_path):
            self.send_response(404)
            self.end_headers()
            return

        with open(file_path, "rb") as served_file:
            body = served_file.read()
        self.send_response(200)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    port = int(os.environ["MOCK_PORT"])
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    sys.stderr.write(f"mock maven repo listening on {port}\n")
    sys.stderr.flush()
    server.serve_forever()
