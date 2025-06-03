#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) ---"
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print each command before executing

echo "Current directory at script start: $(pwd)" # Should be YOUR_REPO_ROOT/ios

echo "Navigating to project root (one level up) for flutter pub get..."
cd .. # Go up from 'ios' to the Flutter project root (YOUR_REPO_ROOT)

echo "Running flutter pub get in $(pwd)..."
flutter pub get
if [ $? -ne 0 ]; then
  echo "flutter pub get FAILED"
  exit 1
fi

echo "Navigating back into iOS directory..."
cd ios # Go back into 'ios' (or 'cd $CI_WORKING_DIRECTORY' if $CI_WORKING_DIRECTORY points to ios)
       # Or, if already in ios and cd .. was just for pub get, this might not be needed
       # or should be 'cd .' to ensure context. Let's try 'cd ios' first from repo root.
       # Given the script is now in ios/ci_scripts, if it runs from ios/, then `cd .` is fine
       # before pod install. Let's simplify assuming it runs from YOUR_REPO_ROOT/ios/

# No 'cd ios' needed here if script is in 'ios/ci_scripts' and runs from 'ios' context.
# 'pwd' after 'flutter pub get' should be YOUR_REPO_ROOT.
# We need to be in YOUR_REPO_ROOT/ios for pod install.
# So after 'flutter pub get' (which is at repo root), we must 'cd ios'

# Re-clarify path after pub get:
# After 'cd ..' and 'flutter pub get', current directory is YOUR_REPO_ROOT
# We need to be in YOUR_REPO_ROOT/ios for pod install.

echo "Ensuring current directory is ios for pod install..."
# If after 'flutter pub get' we are at repo root, then:
if [ ! -f "Podfile" ]; then # Check if Podfile exists in current dir
    echo "Podfile not found in $(pwd), attempting to cd to ios directory (relative to script location's parent)..."
    # This assumes the script itself is at .../ios/ci_scripts/
    # cd ../ # This would go to .../ios/
    # This logic is getting complex based on assumptions.
    # Let's use $CI_PRIMARY_REPOSITORY_PATH if available and reliable.
    cd "$CI_PRIMARY_REPOSITORY_PATH/ios" # Safest way to ensure we are in the ios directory of the repo
fi
echo "Current directory for pod install: $(pwd)"


echo "Running pod install..."
pod install --repo-update
if [ $? -ne 0 ]; then
  echo "pod install FAILED"
  exit 1
fi

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0