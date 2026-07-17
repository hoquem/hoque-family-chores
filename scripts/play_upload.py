#!/usr/bin/env python3
"""Upload the release app bundle to a Google Play testing track.

Mirrors the intent of ``deploy_testflight.sh``: never trust a remembered
version code. Query the highest one Google Play has already seen and use
``highest + 1``, so an upload can't be silently rejected as a duplicate.

The whole thing runs against the Google Play Android Developer API v3 through a
service account. It does NOT build the bundle — ``deploy_playstore.sh`` does
that after this script has chosen the version code, because the code is baked
into the ``.aab`` at build time.

Usage (normally via deploy_playstore.sh, not directly):
    play_upload.py next-version-code   # print highest+1, nothing else
    play_upload.py upload <aab_path>   # upload the built bundle + roll out
"""
import sys
import time

from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Set by deploy_playstore.sh so the two scripts agree on every value.
import os

PACKAGE_NAME = os.environ["PLAY_PACKAGE_NAME"]
SERVICE_ACCOUNT_JSON = os.environ["PLAY_SERVICE_ACCOUNT_JSON"]
TRACK = os.environ.get("PLAY_TRACK", "internal")
SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]


def _service():
    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_JSON, scopes=SCOPES
    )
    # cache_discovery=False: googleapiclient's on-disk cache warns noisily and
    # is pointless for a one-shot script.
    return build("androidpublisher", "v3", credentials=creds, cache_discovery=False)


def _highest_version_code(service) -> int:
    """The largest version code Google Play has ever accepted for this app.

    Reads it from the bundles already uploaded. A fresh app returns nothing, so
    the caller falls back to the pubspec build number.
    """
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit["id"]
    try:
        resp = (
            service.edits()
            .bundles()
            .list(packageName=PACKAGE_NAME, editId=edit_id)
            .execute()
        )
        codes = [int(b["versionCode"]) for b in resp.get("bundles", [])]
        return max(codes) if codes else 0
    finally:
        # A read-only edit must be discarded, never committed.
        service.edits().delete(packageName=PACKAGE_NAME, editId=edit_id).execute()


def next_version_code() -> int:
    return _highest_version_code(_service()) + 1


def upload(aab_path: str) -> int:
    service = _service()
    edit = service.edits().insert(packageName=PACKAGE_NAME, body={}).execute()
    edit_id = edit["id"]

    media = MediaFileUpload(
        aab_path, mimetype="application/octet-stream", resumable=True
    )
    bundle = (
        service.edits()
        .bundles()
        .upload(packageName=PACKAGE_NAME, editId=edit_id, media_body=media)
        .execute()
    )
    version_code = int(bundle["versionCode"])

    # Roll the uploaded bundle out to the testing track, live immediately.
    service.edits().tracks().update(
        packageName=PACKAGE_NAME,
        editId=edit_id,
        track=TRACK,
        body={
            "releases": [
                {"versionCodes": [str(version_code)], "status": "completed"}
            ]
        },
    ).execute()

    service.edits().commit(packageName=PACKAGE_NAME, editId=edit_id).execute()
    return version_code


def main():
    if len(sys.argv) < 2:
        sys.exit("usage: play_upload.py next-version-code | upload <aab>")

    if sys.argv[1] == "next-version-code":
        print(next_version_code())
    elif sys.argv[1] == "upload":
        if len(sys.argv) != 3:
            sys.exit("usage: play_upload.py upload <aab_path>")
        code = upload(sys.argv[2])
        # Give Play a moment; the commit is synchronous but the track takes a
        # few seconds to reflect. Report the code the caller must beat next time.
        time.sleep(2)
        print(f"OK versionCode={code}")
    else:
        sys.exit(f"unknown command: {sys.argv[1]}")


if __name__ == "__main__":
    main()
