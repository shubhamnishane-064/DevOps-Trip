#!/usr/bin/env python3
"""backend.py - tiny test web server for the Nginx lab.
Usage: python3 backend.py <port> <name>
Example: python3 backend.py 9001 backend-1
"""
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9001   # port to listen on
NAME = sys.argv[2] if len(sys.argv) > 2 else f"backend-{PORT}"   # name shown in the answer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":                         # health check URL
            body, code = b"ok\n", 200
        else:                                              # any other URL
            xff = self.headers.get("X-Forwarded-For", "-")  # real client IP set by Nginx
            host = self.headers.get("Host", "-")             # Host header passed by Nginx
            text = (f"Hello from {NAME} (port {PORT})\n"
                    f"Direct peer: {self.client_address[0]}  X-Forwarded-For: {xff}  Host: {host}\n")
            body, code = text.encode(), 200
        self.send_response(code)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Backend", NAME)                # lets curl -I show who answered
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):                          # keep the terminal quiet
        pass


if __name__ == "__main__":
    print(f"{NAME} listening on 127.0.0.1:{PORT}")
    HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
