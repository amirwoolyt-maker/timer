"""Provision Rahyar's authenticated shared tables. Never put the server key in Flutter.

Run interactively: python scripts/setup_appwrite.py
The key is read with getpass, used in memory, and never saved or printed.
"""
import argparse
import getpass
import json
import os
from pathlib import Path
import time
import urllib.error
import urllib.parse
import urllib.request

TABLES = ("posts", "comments", "likes", "messages", "rooms", "members", "scores")
COLUMNS = {"ownerId": 36, "name": 100, "body": 4000, "parentId": 36}
TABLE_PERMISSIONS = ['create("users")']


class ProvisionError(Exception):
    pass


def load_config(path):
    config = json.loads(Path(path).read_text(encoding="utf-8"))
    endpoint = config["APPWRITE_ENDPOINT"].rstrip("/")
    parsed = urllib.parse.urlparse(endpoint)
    if parsed.scheme != "https" or not parsed.hostname or parsed.path != "/v1" or parsed.query or parsed.fragment:
        raise ProvisionError("Expected an HTTPS Appwrite endpoint ending in /v1, without /account.")
    for key in ("APPWRITE_PROJECT_ID", "APPWRITE_DATABASE_ID"):
        value = config.get(key, "")
        if not value or len(value) > 36 or not all(c.isascii() and (c.isalnum() or c in "._-") for c in value):
            raise ProvisionError(f"Invalid public configuration: {key}")
    return config


class Admin:
    def __init__(self, config, key):
        self.endpoint = config["APPWRITE_ENDPOINT"].rstrip("/")
        self.project = config["APPWRITE_PROJECT_ID"]
        self.key = key

    def call(self, method, path, data=None, allow_conflict=False):
        payload = None if data is None else json.dumps(data).encode()
        request = urllib.request.Request(self.endpoint + path, data=payload, method=method, headers={
            "Content-Type": "application/json", "X-Appwrite-Project": self.project,
            "X-Appwrite-Key": self.key,
        })
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                body = response.read()
                return json.loads(body) if body else {}
        except urllib.error.HTTPError as error:
            if allow_conflict and error.code == 409:
                return None
            # Avoid printing a response that might include credentials or user data.
            raise ProvisionError(f"Appwrite rejected {method} {path} (HTTP {error.code}). Check project ID, endpoint, and key scopes.") from None
        except urllib.error.URLError:
            raise ProvisionError("Cannot reach Appwrite. Check the network and endpoint.") from None

    def wait_ready(self, path):
        for _ in range(90):
            resource = self.call("GET", path)
            status = resource.get("status", "available")
            if status == "available":
                return
            if status in ("failed", "stuck"):
                raise ProvisionError(f"Schema creation failed: {path}")
            time.sleep(1)
        raise ProvisionError(f"Schema creation timed out; safely rerun the command: {path}")


def provision(admin, database_id):
    root = f"/tablesdb/{database_id}"
    admin.call("POST", "/tablesdb", {"databaseId": database_id, "name": "Rahyar", "enabled": True}, allow_conflict=True)
    for table in TABLES:
        base = root + f"/tables/{table}"
        admin.call("POST", root + "/tables", {
            "tableId": table, "name": table, "permissions": TABLE_PERMISSIONS,
            "rowSecurity": True, "enabled": True,
        }, allow_conflict=True)
        # Fail closed if an existing table has broader grants. Never silently make a public table.
        actual = admin.call("GET", base)
        if not actual.get("rowSecurity") or sorted(actual.get("$permissions", actual.get("permissions", []))) != TABLE_PERMISSIONS:
            raise ProvisionError(f"Existing table {table} has incompatible permissions. Review it in Console; no access rules were overwritten.")
        for key, size in COLUMNS.items():
            admin.call("POST", base + "/columns/string", {"key": key, "size": size, "required": True, "array": False}, allow_conflict=True)
            column_path = base + "/columns/" + key
            admin.wait_ready(column_path)
            column = admin.call("GET", column_path)
            if column.get("type") != "string" or column.get("size") != size or not column.get("required"):
                raise ProvisionError(f"Existing column {table}.{key} differs from the required schema.")
        admin.call("POST", base + "/indexes", {
            "key": "parent_created", "type": "key",
            "columns": ["parentId", "$createdAt"], "orders": ["ASC", "DESC"],
        }, allow_conflict=True)
        admin.wait_ready(base + "/indexes/parent_created")
        print(f"Ready: {table}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", default=str(Path(__file__).resolve().parents[1] / "config" / "appwrite.json"))
    args = parser.parse_args()
    try:
        config = load_config(args.config)
        key = os.environ.get("APPWRITE_ADMIN_KEY") or getpass.getpass("Temporary Appwrite server key (hidden, never saved): ")
        if not key.strip():
            raise ProvisionError("No key supplied. Create a temporary server key in your own Console; never send it in chat.")
        provision(Admin(config, key.strip()), config["APPWRITE_DATABASE_ID"])
        print("All shared tables are ready. Revoke the temporary key in Console after setup.")
        return 0
    except (ProvisionError, KeyError, ValueError, OSError) as error:
        print(str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
