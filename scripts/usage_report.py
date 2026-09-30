#!/usr/bin/env python3
"""Read-only Chores Star usage report from production Firestore.

Prints aggregate counts only (no names or emails): families, members,
chores created and approved, and "active families" (at least one chore
approved in the window). Downloads say little about a family app; these
numbers say whether families actually use it.

Auth: reuses the Firebase CLI login (``firebase login``) by exchanging its
stored refresh token for an access token. Queries go through the Firestore
REST API under the signed-in account's IAM permissions, so they are
read-only by construction (only ``runQuery`` is called).

Usage::

    python3 scripts/usage_report.py            # 7- and 30-day windows
    python3 scripts/usage_report.py --days 14  # custom window instead of 7
"""
import argparse
import json
import os
import sys
import urllib.parse
import urllib.request
from collections import Counter
from datetime import datetime, timedelta, timezone

PROJECT_ID = os.environ.get("FIREBASE_PROJECT_ID", "hoque-family-chores-app")
FIREBASE_CLI_CONFIG = os.path.expanduser(
    "~/.config/configstore/firebase-tools.json"
)


def cli_oauth_client() -> tuple[str, str]:
    """Read the Firebase CLI's own OAuth client id/secret from the installed CLI.

    The refresh token in the CLI config was issued to that client, so the
    exchange must use it. Reading it from the installed ``firebase-tools``
    (rather than pasting it here) keeps credentials out of the repo.

    :raises SystemExit: If firebase-tools is not installed globally via npm.
    """
    import re
    import subprocess

    root = subprocess.run(
        ["npm", "root", "-g"], capture_output=True, text=True, check=True
    ).stdout.strip()
    try:
        with open(os.path.join(root, "firebase-tools", "lib", "api.js")) as f:
            src = f.read()
    except OSError as e:
        sys.exit(f"firebase-tools not found ({e}). Run `npm i -g firebase-tools`.")
    found = dict(
        re.findall(r'envOverride\("(FIREBASE_CLIENT_(?:ID|SECRET))", "([^"]+)"\)', src)
    )
    return found["FIREBASE_CLIENT_ID"], found["FIREBASE_CLIENT_SECRET"]


# The App Review demo family is staged data, not a real user.
EXCLUDED_FAMILY_NAMES = {"The Demo Family"}

BASE = (
    f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}"
    "/databases/(default)/documents"
)


def access_token() -> str:
    """Exchange the Firebase CLI refresh token for a short-lived access token.

    :raises SystemExit: If the CLI is not logged in.
    """
    try:
        with open(FIREBASE_CLI_CONFIG) as f:
            refresh = json.load(f)["tokens"]["refresh_token"]
    except (OSError, KeyError) as e:
        sys.exit(f"No Firebase CLI login found ({e}). Run `firebase login`.")
    client_id, client_secret = cli_oauth_client()
    body = urllib.parse.urlencode(
        {
            "client_id": client_id,
            "client_secret": client_secret,
            "refresh_token": refresh,
            "grant_type": "refresh_token",
        }
    ).encode()
    with urllib.request.urlopen(
        "https://oauth2.googleapis.com/token", data=body
    ) as r:
        return json.load(r)["access_token"]


def run_query(token: str, collection: str, all_descendants: bool = False):
    """Return every document in a collection (or collection group).

    :param token: OAuth access token.
    :param collection: Collection id, e.g. ``families``.
    :param all_descendants: Query the collection group across all parents.
    :returns: List of Firestore REST document dicts.
    """
    query = {
        "structuredQuery": {
            "from": [
                {"collectionId": collection, "allDescendants": all_descendants}
            ]
        }
    }
    req = urllib.request.Request(
        f"{BASE}:runQuery",
        data=json.dumps(query).encode(),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
    )
    with urllib.request.urlopen(req) as r:
        rows = json.load(r)
    return [row["document"] for row in rows if "document" in row]


def field(doc: dict, name: str):
    """Decode one Firestore REST field to a Python value (scalars only)."""
    v = doc.get("fields", {}).get(name)
    if v is None:
        return None
    if "timestampValue" in v:
        return datetime.fromisoformat(v["timestampValue"].replace("Z", "+00:00"))
    for key in ("stringValue", "integerValue", "booleanValue"):
        if key in v:
            return v[key]
    return None


def family_id_of_task(doc: dict) -> str:
    """Tasks live at ``families/{familyId}/tasks/{taskId}``."""
    parts = doc["name"].split("/documents/")[1].split("/")
    return parts[1]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--days", type=int, default=7, help="short window")
    args = parser.parse_args()

    token = access_token()
    now = datetime.now(timezone.utc)
    short = now - timedelta(days=args.days)
    month = now - timedelta(days=30)

    families = run_query(token, "families")
    excluded = {
        f["name"].rsplit("/", 1)[1]
        for f in families
        if field(f, "name") in EXCLUDED_FAMILY_NAMES
    }
    families = [f for f in families if f["name"].rsplit("/", 1)[1] not in excluded]
    users = [u for u in run_query(token, "users") if field(u, "familyId") not in excluded]
    tasks = [
        t
        for t in run_query(token, "tasks", all_descendants=True)
        if family_id_of_task(t) not in excluded
    ]

    members = Counter(field(u, "familyId") for u in users if field(u, "familyId"))
    roles = Counter(field(u, "role") or "unknown" for u in users)

    def approved_in(since):
        return [
            t
            for t in tasks
            if field(t, "status") == "completed"
            and (field(t, "approvedAt") or datetime.min.replace(tzinfo=timezone.utc)) >= since
        ]

    def created_in(since):
        return [
            t
            for t in tasks
            if (field(t, "createdAt") or datetime.min.replace(tzinfo=timezone.utc)) >= since
        ]

    def new_families(since):
        return [
            f
            for f in families
            if (field(f, "createdAt") or datetime.min.replace(tzinfo=timezone.utc)) >= since
        ]

    print(f"Chores Star usage, {now:%Y-%m-%d %H:%M} UTC (excluding demo family)")
    print(f"  Families:                  {len(families)}")
    print(f"  Families with 2+ members:  {sum(1 for c in members.values() if c >= 2)}")
    print(f"  Users:                     {len(users)}  ({', '.join(f'{k} {v}' for k, v in sorted(roles.items()))})")
    print(f"  Chores ever created:       {len(tasks)}")
    for label, since in ((f"last {args.days} days", short), ("last 30 days", month)):
        approved = approved_in(since)
        print(f"  -- {label}")
        print(f"     New families:           {len(new_families(since))}")
        print(f"     Chores created:         {len(created_in(since))}")
        print(f"     Chores approved:        {len(approved)}")
        print(f"     Active families:        {len({family_id_of_task(t) for t in approved})}  (1+ chore approved)")


if __name__ == "__main__":
    main()
