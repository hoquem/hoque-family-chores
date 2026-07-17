#!/usr/bin/env bash
#
# Build the release app bundle and upload it to a Google Play testing track.
#
# The Android sibling of deploy_testflight.sh. Same rule: query the highest
# version code Google Play has already accepted and build highest+1, so an
# upload can never be rejected as a duplicate. The version code is baked into
# the .aab at build time, which is why we choose it BEFORE building.
#
# Prerequisites (one-time, done in the Play Console — see SETUP below):
#   - a Play Developer API service account JSON at $PLAY_SERVICE_ACCOUNT_JSON
#   - the "Google Play Android Developer API" enabled on its GCP project
#   - the service account granted "Release to testing tracks" for this app
#
# Usage:
#   scripts/deploy_playstore.sh            # full build + upload to internal
#   scripts/deploy_playstore.sh --dry-run  # stop after choosing the version code
#
# SETUP (create the service account):
#   Play Console → Users and permissions → (or) Setup → API access
#     → link/create a Google Cloud project → create a service account
#     → grant it app access with "Release to testing tracks, and manage
#       testing track testers" → download its JSON key.
#   Add Yamin: Play Console → Testing → Internal testing → Testers →
#     create/select an email list containing Yamin's Google account → save,
#     then share the opt-in link with them.
set -euo pipefail

export PLAY_PACKAGE_NAME="com.hoque.familychores"
export PLAY_TRACK="internal"
export PLAY_SERVICE_ACCOUNT_JSON="${PLAY_SERVICE_ACCOUNT_JSON:-$HOME/.playstore/service-account.json}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENV="$REPO_ROOT/scripts/.play-venv"
AAB="$REPO_ROOT/build/app/outputs/bundle/release/app-release.aab"

[ -f "$PLAY_SERVICE_ACCOUNT_JSON" ] || {
  echo "ERROR: service account JSON not found at $PLAY_SERVICE_ACCOUNT_JSON" >&2
  echo "       Set PLAY_SERVICE_ACCOUNT_JSON or place it there. See SETUP in this script." >&2
  exit 1
}

# Isolated venv so the Google client libraries never touch system python.
if [ ! -d "$VENV" ]; then
  echo "Creating Play-upload venv…"
  python3 -m venv "$VENV"
  "$VENV/bin/pip" -q install --upgrade pip
  "$VENV/bin/pip" -q install google-api-python-client google-auth
fi
PY="$VENV/bin/python"

version_name=$(sed -n 's/^version: \([0-9.]*\)+.*/\1/p' "$REPO_ROOT/pubspec.yaml")
current_code=$(sed -n 's/^version: [0-9.]*+\([0-9]*\).*/\1/p' "$REPO_ROOT/pubspec.yaml")

highest_plus_one=$("$PY" "$REPO_ROOT/scripts/play_upload.py" next-version-code)
# First upload ever → the query returns 1 (0 + 1); prefer the real build number
# already in pubspec so Android and iOS stay roughly aligned. After that, always
# beat what Play has.
if [ "$highest_plus_one" -le "$current_code" ]; then
  next="$current_code"
else
  next="$highest_plus_one"
fi
echo "Play highest+1: $highest_plus_one, pubspec: $current_code  →  uploading versionCode $next (${version_name})"

if [ "${1:-}" = "--dry-run" ]; then
  echo "Dry run: stopping before build."
  exit 0
fi

sed -i '' "s/^version: .*/version: ${version_name}+${next}/" "$REPO_ROOT/pubspec.yaml"

cd "$REPO_ROOT"
rm -f "$AAB"
flutter build appbundle --release

[ -f "$AAB" ] || { echo "ERROR: expected bundle not found at $AAB" >&2; exit 1; }

echo "Uploading $(basename "$AAB") to the '$PLAY_TRACK' track…"
"$PY" "$REPO_ROOT/scripts/play_upload.py" upload "$AAB"

echo "Done. Internal testers can update once Play finishes processing (minutes)."
