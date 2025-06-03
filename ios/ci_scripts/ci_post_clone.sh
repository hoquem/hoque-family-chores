#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- Version X ---"
set -e 
set -x 

# --- Attempt to make Flutter available ---
# Option 1: Check if FLUTTER_HOME or a similar variable is set by Xcode Cloud
echo "CI_XCODE_VERSION_ACTUAL is: $CI_XCODE_VERSION_ACTUAL" # Log available vars
echo "Attempting to use system Flutter (if any configured by Xcode Cloud for Xcode 16.2)"

# Option 2: If Xcode Cloud doesn't automatically add Flutter to PATH for this Xcode version
# The Flutter SDK might be available at a known path or an environment variable
# For example, sometimes you need to find and add it.
# This is speculative and might need adjustment based on how Xcode 16.2 environment is set up.
# Search common locations or look for Xcode Cloud specific Flutter environment variables.
# For instance, if Xcode Cloud places it relative to Xcode:
# XCODE_SELECT_PATH=$(xcode-select -p)
# FLUTTER_IN_XCODE_PATH="$XCODE_SELECT_PATH/../SharedFrameworks/Flutter.framework/Versions/A/flutter/bin" 
# Or some other path based on how Xcode 16.2 bundles it.
# if [ -d "$FLUTTER_IN_XCODE_PATH" ]; then
#    export PATH="$FLUTTER_IN_XCODE_PATH:$PATH"
# fi

# A more robust way often suggested if Flutter isn't directly in PATH:
# Clone Flutter manually (this gives you control over the version if needed)
# Remove this if Xcode Cloud's provided Flutter (with Xcode 16.2) should work
# echo "Cloning Flutter stable..."
# git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter_sdk
# export PATH="$HOME/flutter_sdk/bin:$PATH"
# --- End of Flutter availability attempts ---


echo "Initial working directory: $(pwd)" # Expected: /Volumes/workspace/repository/ios/ci_scripts

echo "Navigating to Flutter project root (two levels up) for 'flutter pub get'..."
cd ../.. 
echo "Current directory for 'flutter pub get': $(pwd)"

echo "Verifying Flutter availability..."
which flutter
flutter --version 
flutter doctor -v # More detailed output

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory for 'pod install'..."
cd ios 
echo "Current directory for 'pod install': $(pwd)"

echo "Running pod install..."
pod install --repo-update

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0