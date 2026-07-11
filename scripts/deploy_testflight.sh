#!/usr/bin/env bash
#
# Deploy the iOS app to TestFlight, headless.
#
# Queries App Store Connect for the highest existing build number and uses
# highest+1 — NEVER trust a remembered build number: a duplicate uploads
# "successfully" and is then silently dropped during processing (burned
# builds +8 and +11). Success is declared only when ASC reports the new
# build's processingState as VALID.
#
# Usage:
#   scripts/deploy_testflight.sh            # full deploy
#   scripts/deploy_testflight.sh --dry-run  # stop after picking the build number
#
set -euo pipefail

KEY_ID="55A763B9XW"
ISSUER_ID="2e924c90-75cb-4ef0-a036-574926a7b628"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8"
ASC_APP_ID="6746752194"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA_PATH="$REPO_ROOT/build/ios/ipa/hoque_family_chores.ipa"
ARCHIVE_PATH="$REPO_ROOT/build/ios/archive/Runner.xcarchive"

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# Mint a short-lived ES256 JWT for the ASC API using only openssl + python stdlib
# (python is used solely to convert the DER signature to JOSE raw r||s form).
asc_jwt() {
  local now exp header payload signing_input der_sig
  now=$(date +%s)
  exp=$((now + 1200))
  header=$(printf '{"alg":"ES256","kid":"%s","typ":"JWT"}' "$KEY_ID" | b64url)
  payload=$(printf '{"iss":"%s","iat":%d,"exp":%d,"aud":"appstoreconnect-v1"}' \
    "$ISSUER_ID" "$now" "$exp" | b64url)
  signing_input="$header.$payload"
  der_sig=$(printf '%s' "$signing_input" \
    | openssl dgst -sha256 -sign "$KEY_PATH" -binary | openssl base64 -A)
  python3 - "$signing_input" "$der_sig" <<'PY'
import base64, sys
signing_input, der_b64 = sys.argv[1], sys.argv[2]
der = base64.b64decode(der_b64)
# Minimal DER ECDSA-Sig parse: SEQUENCE { INTEGER r, INTEGER s }
def read_int(buf, i):
    assert buf[i] == 0x02, "expected DER INTEGER"
    n = buf[i + 1]
    val = int.from_bytes(buf[i + 2:i + 2 + n], "big")
    return val, i + 2 + n
i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
r, i = read_int(der, i)
s, _ = read_int(der, i)
raw = r.to_bytes(32, "big") + s.to_bytes(32, "big")
sig = base64.urlsafe_b64encode(raw).rstrip(b"=").decode()
print(f"{signing_input}.{sig}")
PY
}

asc_get() {
  curl -sfg -H "Authorization: Bearer $(asc_jwt)" "https://api.appstoreconnect.apple.com$1"
}

highest_build_number() {
  asc_get "/v1/builds?filter[app]=${ASC_APP_ID}&sort=-version&limit=1&fields[builds]=version" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]; print(d[0]["attributes"]["version"] if d else 0)'
}

build_state() { # $1 = build number; prints processingState or "ABSENT"
  asc_get "/v1/builds?filter[app]=${ASC_APP_ID}&filter[version]=$1&fields[builds]=version,processingState" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin)["data"]; print(d[0]["attributes"]["processingState"] if d else "ABSENT")'
}

[ -f "$KEY_PATH" ] || { echo "ERROR: ASC key not found at $KEY_PATH" >&2; exit 1; }

highest=$(highest_build_number)
next=$((highest + 1))
version_name=$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' "$REPO_ROOT/pubspec.yaml")
echo "Highest build on ASC: $highest  →  deploying ${version_name}+${next}"

if [ "${1:-}" = "--dry-run" ]; then
  echo "Dry run: stopping before build."
  exit 0
fi

sed -i '' "s/^version: .*/version: ${version_name}+${next}/" "$REPO_ROOT/pubspec.yaml"

cd "$REPO_ROOT"
KEY_FLAGS=(-allowProvisioningUpdates
  -authenticationKeyPath "$KEY_PATH"
  -authenticationKeyID "$KEY_ID"
  -authenticationKeyIssuerID "$ISSUER_ID")

flutter build ios --config-only --release
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE_PATH" archive "${KEY_FLAGS[@]}"
xcodebuild -exportArchive -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist ios/exportOptions.plist -exportPath build/ios/ipa "${KEY_FLAGS[@]}"
xcrun altool --upload-app -f "$IPA_PATH" -t ios \
  --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"

echo "Upload accepted; waiting for processing (VALID) — up to 30 min..."
for _ in $(seq 1 60); do
  state=$(build_state "$next")
  echo "  build $next: $state"
  case "$state" in
    VALID) echo "SUCCESS: build ${version_name}+${next} is VALID on TestFlight."; exit 0 ;;
    FAILED|INVALID) echo "ERROR: build $next processing ended in $state" >&2; exit 1 ;;
  esac
  sleep 30
done
echo "ERROR: build $next did not reach VALID within 30 min" >&2
exit 1
