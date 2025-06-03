#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- v5: Bundler Version Fix ---"
set -e # Exit immediately if a command exits with a non-zero status.
set -x # Print each command before executing

# --- Flutter Installation (Keep your working Flutter setup here) ---
FLUTTER_SDK_DIR="$HOME/flutter_ci_sdk"
FLUTTER_VERSION_OR_CHANNEL="stable" # Or your project's specific Flutter version

if [ ! -d "$FLUTTER_SDK_DIR/bin" ]; then
  echo "Cloning Flutter SDK version/channel: $FLUTTER_VERSION_OR_CHANNEL..."
  rm -rf "$FLUTTER_SDK_DIR"
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION_OR_CHANNEL" "$FLUTTER_SDK_DIR"
fi
export PATH="$FLUTTER_SDK_DIR/bin:$PATH"
# --- End Flutter Setup ---

echo "Initial working directory: $(pwd)" 

echo "Navigating to Flutter project root..."
cd ../.. 
echo "Current directory for 'flutter pub get': $(pwd)"

echo "Verifying Flutter availability..."
which flutter
flutter --version 

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory..."
cd ios 
echo "Current directory for 'pod install': $(pwd)"

# --- CocoaPods Installation ---
echo "Setting up and running CocoaPods..."

# Ensure Ruby's user gem bin directory is in the PATH for Bundler/Pod if installed there
USER_GEM_BIN_DIR_CANDIDATE_1=$(ruby -e 'puts Gem.user_dir' 2>/dev/null || true)/bin # For Ruby 2.7+
USER_GEM_BIN_DIR_CANDIDATE_2="$HOME/.gem/ruby/$(ruby -e 'print RUBY_VERSION[0..2]')/bin" # For older Rubies

if [ -d "$USER_GEM_BIN_DIR_CANDIDATE_1" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_1:$PATH"
    echo "User gem bin directory (1) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_1"
elif [ -d "$USER_GEM_BIN_DIR_CANDIDATE_2" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_2:$PATH"
    echo "User gem bin directory (2) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_2"
else
    echo "User gem bin directory not found at common locations. This might be okay if system gems are used."
fi

# Check for Gemfile to use Bundler (recommended)
if [ -f "Gemfile" ]; then
  echo "Gemfile found. Using Bundler."
  
  # --- Install specific Bundler version required by Gemfile.lock ---
  # Extract required Bundler version from Gemfile.lock (e.g., 2.6.7)
  # For simplicity, we'll use the version from your error message.
  # If your Gemfile.lock changes Bundler versions, update this.
  REQUIRED_BUNDLER_VERSION="2.6.7" # As per your error log

  echo "Attempting to install Bundler version $REQUIRED_BUNDLER_VERSION (if not already an exact match or newer compatible)..."
  # Install the specific version. Use --user-install for CI environments.
  # The `|| true` is removed to let `set -e` catch the error if gem install fails badly.
  # We want to ensure a compatible bundler is actually installed and usable.
  gem install bundler -v "$REQUIRED_BUNDLER_VERSION" --no-document --user-install
  
  # Verify the bundler command now points to a compatible version
  # The newly installed bundler should be found first in PATH due to USER_GEM_BIN_DIR addition
  echo "Re-checking Bundler version after install attempt..."
  if command -v bundle >/dev/null 2>&1; then
    echo "Bundler found at: $(which bundle)"
    echo "Bundler version: $(bundle --version)"
  else
    echo "FATAL: Bundler command still not found even after attempting install."
    exit 1
  fi
  # --- End Bundler Version Install ---
  
  echo "Running 'bundle config set --local path vendor/bundle'..."
  bundle config set --local path vendor/bundle # Install gems into ./ios/vendor/bundle
  
  echo "Running 'bundle install'..."
  bundle install --jobs $(sysctl -n hw.ncpu || echo 4) # Install gems specified in Gemfile
  
  echo "Running 'bundle exec pod install --repo-update --verbose'..."
  bundle exec pod install --repo-update --verbose
else
  echo "WARNING: Gemfile not found in ios/ directory."
  # ... (fallback logic for direct pod install, which will likely fail due to Ruby 2.6 issue with latest CocoaPods) ...
  if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods 'pod' command not found directly. Attempting 'gem install cocoapods --user-install'..."
    gem install cocoapods --no-document --user-install # This will likely fail on Ruby 2.6 for latest cocoapods
    if ! command -v pod >/dev/null 2>&1; then
        echo "FATAL: 'pod' command still not found after attempting direct gem install."
        exit 1
    fi
  fi
  echo "CocoaPods 'pod' command found. Path: $(which pod)"
  pod install --repo-update --verbose
fi
# --- End