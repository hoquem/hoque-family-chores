#!/usr/bin/env python3
"""Submit an App Store version to Apple for review via the App Store Connect API.

Usage:
    python3 scripts/submit_appstore_review.py [version_string]
"""
import base64
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error

KEY_ID = os.environ.get("ASC_KEY_ID", "55A763B9XW")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2e924c90-75cb-4ef0-a036-574926a7b628")
KEY_PATH = os.environ.get(
    "ASC_KEY_PATH",
    os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
)
ASC_APP_ID = os.environ.get("ASC_APP_ID", "6746752194")


def get_token():
    cmd = f"""
    b64url() {{ openssl base64 -A | tr '+/' '-_' | tr -d '='; }}
    now=$(date +%s)
    exp=$((now + 1200))
    header=$(printf '{{"alg":"ES256","kid":"{KEY_ID}","typ":"JWT"}}' | b64url)
    payload=$(printf '{{"iss":"{ISSUER_ID}","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}}' "$now" "$exp" | b64url)
    signing_input="$header.$payload"
    der_sig=$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "{KEY_PATH}" -binary | openssl base64 -A)
    python3 - "$signing_input" "$der_sig" <<'INNER'
import base64, sys
signing_input, der_b64 = sys.argv[1], sys.argv[2]
der = base64.b64decode(der_b64)
def read_int(buf, i):
    n = buf[i + 1]
    val = int.from_bytes(buf[i + 2:i + 2 + n], "big")
    return val, i + 2 + n
i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
r, i = read_int(der, i)
s, _ = read_int(der, i)
raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
sig = base64.urlsafe_b64encode(raw).rstrip(b"=").decode()
print(f"{{signing_input}}.{{sig}}")
INNER
    """
    return subprocess.check_output(cmd, shell=True, text=True).strip()


def api_request(method, path, token, payload=None):
    url = f"https://api.appstoreconnect.apple.com{path}"
    data = json.dumps(payload).encode("utf-8") if payload else None
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method=method,
    )
    with urllib.request.urlopen(req) as resp:
        if resp.status == 204:
            return None
        return json.load(resp)


def main():
    if not os.path.exists(KEY_PATH):
        sys.exit(f"Error: ASC key not found at {KEY_PATH}")

    token = get_token()

    target_version = sys.argv[1] if len(sys.argv) > 1 else None

    # Find prepare_for_submission version
    versions = api_request("GET", f"/v1/apps/{ASC_APP_ID}/appStoreVersions", token)
    eligible = None
    for v in versions.get("data", []):
        v_str = v["attributes"]["versionString"]
        state = v["attributes"]["appStoreState"]
        if target_version and v_str == target_version:
            eligible = v
            break
        elif not target_version and state == "PREPARE_FOR_SUBMISSION":
            eligible = v
            break

    if not eligible:
        sys.exit(f"No version found in PREPARE_FOR_SUBMISSION state.")

    version_id = eligible["id"]
    version_str = eligible["attributes"]["versionString"]
    print(f"Targeting version {version_str} ({version_id})")

    # 1. Create reviewSubmission
    print("Creating review submission container...")
    sub = api_request(
        "POST",
        "/v1/reviewSubmissions",
        token,
        {
            "data": {
                "type": "reviewSubmissions",
                "attributes": {"platform": "IOS"},
                "relationships": {
                    "app": {"data": {"type": "apps", "id": ASC_APP_ID}}
                },
            }
        },
    )
    sub_id = sub["data"]["id"]

    # 2. Add version item
    print("Attaching version to review submission...")
    api_request(
        "POST",
        "/v1/reviewSubmissionItems",
        token,
        {
            "data": {
                "type": "reviewSubmissionItems",
                "relationships": {
                    "reviewSubmission": {
                        "data": {"type": "reviewSubmissions", "id": sub_id}
                    },
                    "appStoreVersion": {
                        "data": {"type": "appStoreVersions", "id": version_id}
                    },
                },
            }
        },
    )

    # 3. Submit
    print("Submitting to Apple...")
    res = api_request(
        "PATCH",
        f"/v1/reviewSubmissions/{sub_id}",
        token,
        {
            "data": {
                "type": "reviewSubmissions",
                "id": sub_id,
                "attributes": {"submitted": True},
            }
        },
    )
    state = res["data"]["attributes"]["state"]
    print(f"Submission successful! State: {state}")


if __name__ == "__main__":
    main()
