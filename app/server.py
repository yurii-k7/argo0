"""Tiny demo app: shows its version and serves /healthz. Standard library only."""
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

VERSION = os.environ.get("APP_VERSION", "dev")
HOST = os.environ.get("HOSTNAME", "unknown")

PAGE = f"""<!doctype html>
<html><head><title>argo0-app</title>
<style>body{{font-family:sans-serif;text-align:center;margin-top:15vh}}
h1{{font-size:4rem}}</style></head>
<body><h1>argo0-app v{VERSION}</h1><p>served by pod <code>{HOST}</code></p></body></html>
""".encode()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body, ctype = b"ok", "text/plain"
        else:
            body, ctype = PAGE, "text/html; charset=utf-8"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(f"[{VERSION}] {self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
