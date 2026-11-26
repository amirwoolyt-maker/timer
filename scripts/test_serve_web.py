"""HTTP checks for the local Flutter web preview, using only Python's stdlib."""

from functools import partial
from http.server import ThreadingHTTPServer
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Thread
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from serve_web import FlutterWebHandler


class PreviewServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = TemporaryDirectory(prefix="rahyar-preview-test-")
        root = Path(cls.directory.name)
        (root / "index.html").write_text("<html>rahyar</html>", encoding="utf-8")
        (root / "sqlite3.wasm").write_bytes(b"\x00asm")
        cls.server = ThreadingHTTPServer(
            ("127.0.0.1", 0),
            partial(FlutterWebHandler, directory=str(root)),
        )
        cls.thread = Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()
        cls.directory.cleanup()

    def test_security_and_revalidation_headers(self):
        with urlopen(self.base + "/") as response:
            self.assertEqual(response.headers["Cross-Origin-Opener-Policy"], "same-origin")
            self.assertEqual(response.headers["Cross-Origin-Embedder-Policy"], "require-corp")
            self.assertEqual(response.headers["Cross-Origin-Resource-Policy"], "same-origin")
            self.assertEqual(response.headers["Cache-Control"], "no-cache")

    def test_client_routes_fall_back_to_index(self):
        with urlopen(self.base + "/tasks?view=today") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.read(), b"<html>rahyar</html>")

    def test_missing_scripts_do_not_receive_html(self):
        with self.assertRaises(HTTPError) as raised:
            urlopen(self.base + "/missing.js")
        self.assertEqual(raised.exception.code, 404)
        raised.exception.close()

    def test_wasm_mime_type(self):
        with urlopen(self.base + "/sqlite3.wasm") as response:
            self.assertEqual(response.headers.get_content_type(), "application/wasm")
            self.assertEqual(response.read(), b"\x00asm")

    def test_health_endpoint_get_and_head(self):
        with urlopen(self.base + "/healthz") as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.read(), b"ok")
        with urlopen(Request(self.base + "/healthz", method="HEAD")) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(response.headers["Content-Length"], "2")
            self.assertEqual(response.read(), b"")


if __name__ == "__main__":
    unittest.main()
