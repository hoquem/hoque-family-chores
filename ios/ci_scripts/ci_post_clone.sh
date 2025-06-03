#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- CORRECTED ---"
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print each command before executing (very useful for debugging)

echo "Initial working directory: $(pwd)" # Expected: /Volumes/workspace/repository/ios/ci_scripts

# Navigate to the Flutter project root (two levels up from ios/ci_scripts)
echo "Navigating to Flutter project root for 'flutter pub get'..."
cd ../.. 
# Now the current directory should be /Volumes/workspace/repository/ (the Flutter project root)
echo "Current directory for 'flutter pub get': $(pwd)"

# --- Add these lines to debug Flutter path ---
echo "Attempting to find flutter command..."
which flutter # Check if flutter is in PATH and where it is
flutter --version # Check the version and confirm it's runnable
# --- End of debug lines ---

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory for 'pod install'..."
cd ios # From the Flutter project root, go into the 'ios' directory
# Now the current directory should be /Volumes/workspace/repository/ios/
echo "Current directory for 'pod install': $(pwd)"

echo "Running pod install..."
pod install --repo-update

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0