#!/bin/sh
echo "--- Executing ci_post_clone.sh (from ios/ci_scripts/) --- v4: Pod Install Focus ---"
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

echo "Initial working directory: $(pwd)" # Expected: .../ios/ci_scripts

echo "Navigating to Flutter project root..."
cd ../.. # From ios/ci_scripts to Flutter project root
echo "Current directory for 'flutter pub get': $(pwd)"

echo "Verifying Flutter availability..."
which flutter
flutter --version
# flutter doctor -v # Keep if needed, can be verbose

echo "Running flutter pub get..."
flutter pub get

echo "Navigating back to 'ios' directory..."
cd ios
echo "Current directory for 'pod install': $(pwd)" # Expected: .../repository/ios

# --- CocoaPods Installation ---
echo "Setting up and running CocoaPods..."

# Ensure Ruby's user gem bin directory is in the PATH for Bundler/Pod if installed there
# This path might vary slightly based on the Ruby version on the CI agent
USER_GEM_BIN_DIR_CANDIDATE_1=$(ruby -e 'puts Gem.user_dir' 2>/dev/null || true)/bin
USER_GEM_BIN_DIR_CANDIDATE_2="$HOME/.gem/ruby/$(ruby -e 'print RUBY_VERSION[0..2]')/bin" # Common for user gems

if [ -d "$USER_GEM_BIN_DIR_CANDIDATE_1" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_1:$PATH"
    echo "User gem bin directory (1) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_1"
elif [ -d "$USER_GEM_BIN_DIR_CANDIDATE_2" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_2:$PATH"
    echo "User gem bin directory (2) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_2"
else
    echo "User gem bin directory not found at common locations."
fi

# Check for Gemfile to use Bundler (recommended)
if [ -f "Gemfile" ]; then
  echo "Gemfile found. Using Bundler."

  # Install Bundler if not already available
  if ! command -v bundle >/dev/null 2>&1; then
    echo "Bundler not found. Installing Bundler (user scope)..."
    gem install bundler --no-document --user-install # Installs to user directory
    # Re-check for bundler after attempting install
    if ! command -v bundle >/dev/null 2>&1; then
        echo "FATAL: Bundler still not found after attempting install."
        # Try to see if it's in a non-standard path before exiting
        ls -la $HOME/.gem/ruby/*/bin/bundle || true
        exit 1
    fi
  fi

  echo "Bundler found/installed. Path: $(which bundle)"
  echo "Running 'bundle config set --local path vendor/bundle' to install gems locally within project."
  bundle config set --local path vendor/bundle # Installs gems into ./ios/vendor/bundle

  echo "Running 'bundle install'..."
  bundle install --jobs $(sysctl -n hw.ncpu || echo 4) # Install gems, use hw.ncpu for macOS

  echo "Running 'bundle exec pod install --repo-update --verbose'..."
  bundle exec pod install --repo-update --verbose
else
  echo "WARNING: Gemfile not found in ios/ directory."
  echo "Attempting direct 'pod install'. This may fail or use an unexpected CocoaPods version."
  echo "It is HIGHLY recommended to create a Gemfile in your ios/ directory."

  # Attempt to install CocoaPods via gem if not found and no Gemfile (less ideal)
  if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods 'pod' command not found directly. Attempting 'gem install cocoapods --user-install'..."
    gem install cocoapods --no-document --user-install
    # Re-check for pod after attempting install
    if ! command -v pod >/dev/null 2>&1; then
        echo "FATAL: 'pod' command still not found after attempting direct gem install."
        exit 1
    fi
  fi
  echo "CocoaPods 'pod' command found. Path: $(which pod)"
  pod install --repo-update --verbose
fi
# --- End CocoaPods Installation ---

echo "--- ci_post_clone.sh (from ios/ci_scripts/) finished successfully ---"
exit 0