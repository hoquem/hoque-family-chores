#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- Activating Flutter ---"
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print each command before executing (very useful for debugging)

# --- Explicitly setup Flutter ---
# Define a path for the Flutter SDK to be cloned into for this CI run.
# Using $HOME is common as it's usually writable.
FLUTTER_SDK_DIR="$HOME/flutter_ci_sdk"
# Specify the Flutter version/channel you want to use.
# Match this with your project's requirements. Example: 'stable', 'beta', or a specific tag like '3.22.1'
FLUTTER_VERSION_OR_CHANNEL="stable" # Or use your project's specific Flutter version, e.g., "3.22.1"

# Clone Flutter only if the directory doesn't already exist
if [ ! -d "$FLUTTER_SDK_DIR/bin" ]; then # Check for the bin directory to be more specific
  echo "Cloning Flutter SDK version/channel: $FLUTTER_VERSION_OR_CHANNEL..."
  # Remove directory if it exists but is incomplete from a previous failed run
  rm -rf "$FLUTTER_SDK_DIR"
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION_OR_CHANNEL" "$FLUTTER_SDK_DIR"
else
  echo "Flutter SDK already found at $FLUTTER_SDK_DIR. Assuming it's the correct version."
  # Optionally, you could add logic here to check the version and re-clone if it doesn't match.
fi

# Add the cloned Flutter SDK's bin directory to the PATH for this script session
export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
# --- End Flutter Setup ---

echo "Initial working directory: $(pwd)" # Expected: .../ios/ci_scripts

echo "Navigating to Flutter project root (two levels up from ios/ci_scripts)..."
cd ../.. 
echo "Current directory for 'flutter pub get': $(pwd)" # Expected: .../repository (Flutter project root)

echo "Verifying Flutter availability..."
which flutter # Should now point to the cloned SDK in $FLUTTER_SDK_DIR/bin/flutter
flutter --version # Will show the version from the cloned SDK
flutter doctor -v # Provides detailed environment info, good for logging

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory for 'pod install'..."
cd ios 
echo "Current directory for 'pod install': $(pwd)" # Expected: .../repository/ios

# --- CocoaPods Installation using Bundler (Recommended, from previous advice) ---
echo "Checking for Gemfile and preparing for pod install..."
if [ -f "Gemfile" ]; then
  echo "Gemfile found."
  if ! command -v bundle >/dev/null 2>&1; then
    echo "Bundler not found. Installing Bundler (user scope)..."
    gem install bundler --no-document --user-install # --user-install to avoid permission issues
    # Add user gem bin to PATH if not already there
    USER_GEM_BIN_PATH=$(ruby -e 'puts Gem.user_dir')/bin
    export PATH="$USER_GEM_BIN_PATH:$PATH"
    # Re-check for bundler
    if ! command -v bundle >/dev/null 2>&1; then
        echo "Failed to install or find bundler even after attempting install."
        exit 1
    fi
  fi
  echo "Running 'bundle install'..."
  bundle install 
  echo "Running 'bundle exec pod install --repo-update'..."
  bundle exec pod install --repo-update 
else
  echo "WARNING: Gemfile not found in ios/ directory. Attempting direct 'pod install --repo-update'."
  echo "If 'pod' command is not found next, creating a Gemfile in your ios/ directory is highly recommended."
  pod install --repo-update 
fi
# --- End CocoaPods Installation ---

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0