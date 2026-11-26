import json
from pathlib import Path
import tempfile
import unittest
from setup_appwrite import COLUMNS, TABLES, TABLE_PERMISSIONS, ProvisionError, load_config, provision


class FakeAdmin:
    def __init__(self, insecure=False):
        self.calls = []
        self.insecure = insecure

    def call(self, method, path, data=None, allow_conflict=False):
        self.calls.append((method, path, data))
        if method == "GET" and "/columns/" in path:
            key = path.rsplit("/", 1)[1]
            return {"type": "string", "size": COLUMNS[key], "required": True}
        return {"rowSecurity": not self.insecure, "$permissions": TABLE_PERMISSIONS}

    def wait_ready(self, path):
        pass


class SetupTest(unittest.TestCase):
    def test_only_authenticated_create_and_owner_row_security(self):
        fake = FakeAdmin()
        provision(fake, "testdb")
        tables = [data for method, path, data in fake.calls if method == "POST" and path.endswith("/tables")]
        self.assertEqual(len(tables), len(TABLES))
        for table in tables:
            self.assertTrue(table["rowSecurity"])
            self.assertEqual(table["permissions"], ['create("users")'])
            self.assertNotIn('read("any")', table["permissions"])

    def test_existing_insecure_table_is_not_silently_reused(self):
        with self.assertRaises(ProvisionError):
            provision(FakeAdmin(insecure=True), "testdb")

    def test_endpoint_with_account_path_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / "config.json"
            path.write_text(json.dumps({"APPWRITE_ENDPOINT": "https://fra.cloud.appwrite.io/v1/account", "APPWRITE_PROJECT_ID": "123", "APPWRITE_DATABASE_ID": "rahyar"}))
            with self.assertRaises(ProvisionError):
                load_config(path)


if __name__ == "__main__":
    unittest.main()
