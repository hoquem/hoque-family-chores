#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- V3 ---"
set -e 
set -x 

# --- Explicitly setup Flutter ---
FLUTTER_SDK_DIR="$HOME/flutter_ci_sdk" # A temporary location for Flutter SDK

# Check if Flutter is already available from Xcode Cloud's environment
# This might be set if a Flutter version is selected in the Workflow Environment settings
# Often, Xcode Cloud makes a Flutter version available with selected Xcode
echo "Checking for existing Flutter in PATH..."
if command -v flutter >/dev/null 2>&1; then
    echo "Flutter found in PATH. Version:"
    flutter --version
else
    echo "Flutter not found in PATH. Attempting to clone and setup Flutter."
    # Remove any old clone to ensure freshness
    rm -rf "$FLUTTER_SDK_DIR"
    # Clone a specific stable version of Flutter (adjust version as needed)
    git clone https://github.com/flutter/flutter.git --depth 1 --branch stable "$FLUTTER_SDK_DIR"
    # Add the cloned Flutter's bin directory to the PATH
    export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
    
    echo "Flutter cloned to $FLUTTER_SDK_DIR. PATH updated."
    echo "Verifying cloned Flutter..."
    which flutter
    flutter --version
fi
# --- End Flutter Setup ---

echo "Initial working directory: $(pwd)" # Expected: .../ios/ci_scripts

echo "Navigating to Flutter project root..."
cd ../.. # From ios/ci_scripts to Flutter project root
echo "Current directory for 'flutter pub get': $(pwd)"

echo "Running flutter doctor -v..." # Get detailed Flutter environment info
flutter doctor -v

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory..."
cd ios 
echo "Current directory for 'pod install': $(pwd)"

echo "Running pod install..."
pod install --repo-update

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0