"""Preview a Flutter web build with the headers required by Drift WASM.

Local preview only. Use Caddy (or the Docker image) on a public server.
"""

from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit


class FlutterWebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "text/javascript",
        ".json": "application/json",
    }

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def _health_response(self, include_body: bool) -> bool:
        if urlsplit(self.path).path == "/healthz":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", "2")
            self.end_headers()
            if include_body:
                self.wfile.write(b"ok")
            return True
        return False

    def do_GET(self) -> None:
        if self._health_response(include_body=True):
            return
        super().do_GET()

    def do_HEAD(self) -> None:
        if self._health_response(include_body=False):
            return
        super().do_HEAD()

    def send_head(self):
        request_path = urlsplit(self.path).path
        file_path = Path(self.translate_path(self.path))
        if not file_path.exists() and not Path(request_path).suffix:
            self.path = "/index.html"
        return super().send_head()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", type=Path, default=Path("build/web"))
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()
    root = args.directory.resolve()
    if not (root / "index.html").is_file():
        parser.error(f"No Flutter web build in {root}; run flutter build web first.")
    server = ThreadingHTTPServer(
        (args.bind, args.port), partial(FlutterWebHandler, directory=str(root))
    )
    print(f"Serving {root} at http://{args.bind}:{args.port}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
