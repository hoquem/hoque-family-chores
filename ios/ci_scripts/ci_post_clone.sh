#!/bin/sh
# Xcode Cloud Post-Clone Script (ios/ci_scripts/ci_post_clone.sh)
# Purpose: Set up Flutter, Firebase, and CocoaPods dependencies after cloning.

echo "--- Executing ci_post_clone.sh --- Version: 2.0.2 ---"
echo "Timestamp: $(date)"
echo "CI Workspace: $CI_WORKSPACE"
echo "Current Directory: $(pwd)"
echo "Script Location: $0"
echo "Script Directory: $(dirname "$0")"

# Exit immediately if a command exits with a non-zero status.
set -e
# Print each command before executing (for debugging).
set -x

# --- 1. Environment Variable Checks ---
echo "--- Checking Required Environment Variables ---"
# Flutter Version
: "${FLUTTER_VERSION_TAG:?Error: FLUTTER_VERSION_TAG is not set. Please set this in Xcode Cloud Workflow Environment Variables (e.g., 3.19.6)}"

# Firebase related variables (from firebase.json and firebase_options.dart structure)
# These should be set as Secret Environment Variables in Xcode Cloud
: "${FIREBASE_API_KEY_PROJECT:?Error: FIREBASE_API_KEY_PROJECT is not set. This is the main Firebase Web API Key for your project.}" # Renamed to avoid conflict if user has another API_KEY
: "${FIREBASE_APP_ID_IOS:?Error: FIREBASE_APP_ID_IOS is not set. Get this from your Firebase project settings for the iOS app.}"
: "${FIREBASE_MESSAGING_SENDER_ID:?Error: FIREBASE_MESSAGING_SENDER_ID is not set. Get this from Firebase project settings.}"
: "${FIREBASE_PROJECT_ID:?Error: FIREBASE_PROJECT_ID is not set. Get this from Firebase project settings.}"
: "${FIREBASE_STORAGE_BUCKET_IOS:?Error: FIREBASE_STORAGE_BUCKET_IOS is not set. Get this from Firebase project settings (if using Storage).}"
: "${FIREBASE_AUTH_DOMAIN:?Error: FIREBASE_AUTH_DOMAIN is not set. Get this from Firebase project settings (e.g., project-id.firebaseapp.com).}"
# Add others if your firebase_options.dart requires them (e.g., MEASUREMENT_ID, DATABASE_URL)

# Custom .env variables from user's project
: "${SOME_API_KEY:?Error: SOME_API_KEY from .env is not set.}"
: "${SOME_API_SECRET:?Error: SOME_API_SECRET from .env is not set.}"


# --- 2. Flutter SDK Installation ---
echo "--- Setting up Flutter SDK (Version: $FLUTTER_VERSION_TAG) ---"
FLUTTER_SDK_BASE_DIR="$HOME/flutter_sdks" # Base directory for Flutter SDKs
FLUTTER_SDK_DIR_NAME="flutter_$FLUTTER_VERSION_TAG" # e.g., flutter_3.19.6
FLUTTER_SDK_PATH="$FLUTTER_SDK_BASE_DIR/$FLUTTER_SDK_DIR_NAME"

if [ ! -d "$FLUTTER_SDK_PATH/bin" ]; then
  echo "Flutter SDK version $FLUTTER_VERSION_TAG not found at $FLUTTER_SDK_PATH. Cloning..."
  mkdir -p "$FLUTTER_SDK_BASE_DIR"
  rm -rf "$FLUTTER_SDK_PATH" # Remove if exists but incomplete
  git clone https://github.com/flutter/flutter.git --depth 1 --branch "$FLUTTER_VERSION_TAG" "$FLUTTER_SDK_PATH"
else
  echo "Flutter SDK version $FLUTTER_VERSION_TAG found at $FLUTTER_SDK_PATH."
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
echo "Flutter SDK Path: $FLUTTER_SDK_PATH"
which flutter
flutter --version

# --- 3. Determine Project Root (Robustly) ---
echo "--- Determining Project Root ---"
# Debug information about the environment
echo "Debug - Current directory: $(pwd)"
echo "Debug - Script location: $0"
echo "Debug - Script directory: $(dirname "$0")"
echo "Debug - CI_WORKSPACE: $CI_WORKSPACE"
echo "Debug - Directory listing of current location:"
ls -la

# Determine the project root more robustly
# Method 1: Use CI_WORKSPACE if available
if [ -n "$CI_WORKSPACE" ] && [ -d "$CI_WORKSPACE" ]; then
  echo "Using CI_WORKSPACE as project root"
  PROJECT_ROOT="$CI_WORKSPACE"
# Method 2: Determine from script location (assuming script is in ios/ci_scripts)
elif [ -f "$(pwd)/pubspec.yaml" ]; then
  echo "Found pubspec.yaml in current directory, using as project root"
  PROJECT_ROOT="$(pwd)"
elif [ -f "$(pwd)/../pubspec.yaml" ]; then
  echo "Found pubspec.yaml one level up, using that as project root"
  PROJECT_ROOT="$(pwd)/.."
elif [ -f "$(pwd)/../../pubspec.yaml" ]; then
  echo "Found pubspec.yaml two levels up, using that as project root"
  PROJECT_ROOT="$(pwd)/../.."
# Method 3: If we're in ios/ci_scripts, go up two directories
elif [ "$(basename "$(pwd)")" = "ci_scripts" ] && [ "$(basename "$(dirname "$(pwd)")")" = "ios" ]; then
  echo "Current directory structure suggests we're in ios/ci_scripts, going up two levels"
  PROJECT_ROOT="$(pwd)/../.."
# Method 4: If we're in ios directory, go up one directory
elif [ "$(basename "$(pwd)")" = "ios" ]; then
  echo "Current directory is ios, going up one level"
  PROJECT_ROOT="$(pwd)/.."
# Method 5: If we're in /Volumes/workspace/repository, use that
elif [ "$(pwd)" = "/Volumes/workspace/repository" ]; then
  echo "Current directory is /Volumes/workspace/repository, using that"
  PROJECT_ROOT="/Volumes/workspace/repository"
# Method 6: If we're in /Volumes/workspace/repository/ios/ci_scripts, go up two levels
elif [ "$(pwd)" = "/Volumes/workspace/repository/ios/ci_scripts" ]; then
  echo "Current directory is /Volumes/workspace/repository/ios/ci_scripts, going up two levels"
  PROJECT_ROOT="/Volumes/workspace/repository"
# Fallback: Use the parent directory of the script location
else
  echo "Using fallback method to determine project root"
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

# Verify the project root
echo "Determined PROJECT_ROOT: $PROJECT_ROOT"
if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Error: Determined project root '$PROJECT_ROOT' does not exist!"
  exit 1
fi

# Navigate to the project root
cd "$PROJECT_ROOT"
echo "Current Directory (Project Root): $(pwd)"

# Verify we're in the right place by checking for key files
echo "Verifying project root location..."
if [ -f "pubspec.yaml" ]; then
  echo "✓ Found pubspec.yaml in project root"
elif [ -d "ios" ] && [ -d "android" ]; then
  echo "✓ Found ios and android directories in project root"
else
  echo "Warning: Could not verify project root. Missing pubspec.yaml or ios/android directories."
  echo "Directory contents of determined project root:"
  ls -la
fi

# --- 4. Create .env File from CI Variables ---
echo "--- Creating .env file ---"

# Define potential .env locations in order of preference
ENV_FILE_LOCATIONS=(
  "$PROJECT_ROOT/.env"                    # Project root (preferred)
  "$PROJECT_ROOT/ios/.env"                # iOS directory
  "$PROJECT_ROOT/ios/Runner/.env"         # iOS Runner directory
  "$PROJECT_ROOT/ios/Flutter/.env"        # iOS Flutter directory
  "$(pwd)/.env"                           # Current directory
)

# Try each location until we find a writable one
ENV_FILE_PATH=""
for location in "${ENV_FILE_LOCATIONS[@]}"; do
  echo "Trying to use .env location: $location"
  if [ -w "$(dirname "$location")" ]; then
    ENV_FILE_PATH="$location"
    echo "✓ Found writable location for .env: $ENV_FILE_PATH"
    break
  else
    echo "× Directory $(dirname "$location") is not writable."
    echo "  Permissions: $(ls -ld "$(dirname "$location")" 2>/dev/null || echo "Cannot access directory")"
  fi
done

# If no writable location was found, try to create directories
if [ -z "$ENV_FILE_PATH" ]; then
  echo "No writable location found for .env file. Attempting to create directories..."
  
  # Try to create a directory in the current working directory
  FALLBACK_DIR="$(pwd)/flutter_env"
  mkdir -p "$FALLBACK_DIR" 2>/dev/null || true
  
  if [ -d "$FALLBACK_DIR" ] && [ -w "$FALLBACK_DIR" ]; then
    ENV_FILE_PATH="$FALLBACK_DIR/.env"
    echo "Created fallback directory for .env: $ENV_FILE_PATH"
  else
    echo "FATAL: Could not find or create a writable location for .env file!"
    echo "Current user: $(whoami)"
    echo "Current directory: $(pwd)"
    echo "Directory permissions: $(ls -ld "$(pwd)")"
    exit 1
  fi
fi

echo "Writing to $ENV_FILE_PATH..."

# Firebase variables (these names should match what your firebase_options.dart expects or how you load them)
# The firebase.json values are primarily for the flutterfire CLI.
# The actual values used at runtime come from firebase_options.dart, which are typically hardcoded
# during `flutterfire configure` or loaded from environment variables if you've customized it.
# For CI, it's best to explicitly provide all necessary Firebase config values as environment variables.

echo "FIREBASE_API_KEY=${FIREBASE_API_KEY_PROJECT}" > "$ENV_FILE_PATH" # Using the renamed variable
echo "FIREBASE_APP_ID_IOS=${FIREBASE_APP_ID_IOS}" >> "$ENV_FILE_PATH"
echo "FIREBASE_MESSAGING_SENDER_ID=${FIREBASE_MESSAGING_SENDER_ID}" >> "$ENV_FILE_PATH"
echo "FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}" >> "$ENV_FILE_PATH"
echo "FIREBASE_STORAGE_BUCKET_IOS=${FIREBASE_STORAGE_BUCKET_IOS}" >> "$ENV_FILE_PATH"
echo "FIREBASE_AUTH_DOMAIN=${FIREBASE_AUTH_DOMAIN}" >> "$ENV_FILE_PATH"
# Add other Firebase related variables if needed by your app's custom .env loading logic

# Custom .env variables from user's project
echo "SOME_API_KEY=${SOME_API_KEY}" >> "$ENV_FILE_PATH"
echo "SOME_API_SECRET=${SOME_API_SECRET}" >> "$ENV_FILE_PATH"

echo ".env file created successfully at: $ENV_FILE_PATH"
echo ".env file content (redacted secrets):"
grep -v "KEY\|SECRET\|TOKEN" "$ENV_FILE_PATH" || echo "No non-secret content to show"

# Create symbolic links to the .env file in common locations for redundancy
echo "Creating symbolic links to .env file in common locations..."
if [ "$ENV_FILE_PATH" != "$PROJECT_ROOT/.env" ] && [ -w "$PROJECT_ROOT" ]; then
  ln -sf "$ENV_FILE_PATH" "$PROJECT_ROOT/.env" 2>/dev/null || echo "Could not create symlink at $PROJECT_ROOT/.env"
fi
if [ "$ENV_FILE_PATH" != "$PROJECT_ROOT/ios/Runner/.env" ] && [ -w "$PROJECT_ROOT/ios/Runner" ]; then
  ln -sf "$ENV_FILE_PATH" "$PROJECT_ROOT/ios/Runner/.env" 2>/dev/null || echo "Could not create symlink at $PROJECT_ROOT/ios/Runner/.env"
fi

# --- 5. Verify GoogleService-Info.plist ---
echo "--- Verifying GoogleService-Info.plist ---"
# The GoogleService-Info.plist should be committed to your repository at ios/Runner/GoogleService-Info.plist
# if it's not, you'd need a pre-xcodebuild script to create it or download it.
GOOGLE_SERVICES_PLIST_PATH="$PROJECT_ROOT/ios/Runner/GoogleService-Info.plist"
if [ -f "$GOOGLE_SERVICES_PLIST_PATH" ]; then
  echo "GoogleService-Info.plist found at $GOOGLE_SERVICES_PLIST_PATH."
else
  echo "Error: GoogleService-Info.plist not found at $GOOGLE_SERVICES_PLIST_PATH."
  echo "Please ensure it is correctly placed in your repository (e.g., at $PROJECT_ROOT/ios/Runner/GoogleService-Info.plist)."
  echo "If it's generated dynamically, ensure your ci_pre_xcodebuild.sh script handles its creation."
  exit 1 # Critical file, exit if not found
fi

# --- 6. Flutter Project Setup & Verification ---
echo "--- Flutter Project Setup & Verification ---"
echo "Running flutter doctor -v..."
flutter doctor -v

echo "Running flutter pub get..."
flutter pub get

echo "Running flutter analyze (warnings won't fail the build)..."
flutter analyze --no-fatal-warnings || echo "Flutter analyze completed with warnings (non-fatal for CI)"

echo "Preparing for tests: Creating test-results directory..."
mkdir -p test-results

echo "Running flutter test (with USE_MOCK_DATA=true)..."
# Set USE_MOCK_DATA to true so tests use MockDataService
# Output test results in machine-readable format for CI processing
USE_MOCK_DATA=true flutter test --machine > test-results/flutter-test-results.json

echo "Running Flutter iOS build verification (simulator, no codesign)..."
# This step verifies that the Flutter part of the iOS app can compile.
# It will use the .env file created above.
# Firebase initialization in main.dart should use these values if you've set up flutter_dotenv.
flutter build ios --no-codesign --simulator

# --- 7. Navigate to ios Directory for CocoaPods ---
echo "--- Navigating to ios Directory for CocoaPods ---"
IOS_DIR="$PROJECT_ROOT/ios"
cd "$IOS_DIR"
echo "Current Directory (iOS): $(pwd)"

# --- 8. CocoaPods Installation (using Bundler) ---
echo "--- Setting up and running CocoaPods via Bundler ---"

# Ensure Ruby's user gem bin directory is in the PATH
# This helps find user-installed versions of Bundler/CocoaPods
USER_GEM_BIN_DIR_CANDIDATE_1="$(ruby -e 'puts Gem.user_dir' 2>/dev/null || true)/bin"
USER_GEM_BIN_DIR_CANDIDATE_2="$HOME/.gem/ruby/$(ruby -e 'print RUBY_VERSION[0..2]')/bin"

if [ -d "$USER_GEM_BIN_DIR_CANDIDATE_1" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_1:$PATH"
    echo "User gem bin directory (1) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_1"
elif [ -d "$USER_GEM_BIN_DIR_CANDIDATE_2" ]; then
    export PATH="$USER_GEM_BIN_DIR_CANDIDATE_2:$PATH"
    echo "User gem bin directory (2) added to PATH: $USER_GEM_BIN_DIR_CANDIDATE_2"
else
    echo "User gem bin directory not found at common locations. This might be okay if system gems are used."
fi
echo "Updated PATH: $PATH"

if [ -f "Gemfile" ]; then
  echo "Gemfile found. Using Bundler."
  
  # REQUIRED_BUNDLER_VERSION should match the version that created Gemfile.lock
  # or a version known to be compatible with Xcode Cloud's Ruby and your Gemfile.
  # User's Gemfile specifies cocoapods '~> 1.11.3', which worked with bundler 2.2.x - 2.3.x
  # Xcode Cloud's default Ruby might be older. Let's stick to a known compatible bundler.
  REQUIRED_BUNDLER_VERSION="2.2.33" 
  echo "Target Bundler version (approx): $REQUIRED_BUNDLER_VERSION"

  echo "Checking current Bundler version..."
  if command -v bundle >/dev/null 2>&1; then
    CURRENT_BUNDLER_VERSION=$(bundle --version | awk '{print $3}')
    echo "Found Bundler version: $CURRENT_BUNDLER_VERSION"
    # Attempt to install specific version if current one is different.
    # This handles cases where system bundler is too new or too old.
    if [ "$CURRENT_BUNDLER_VERSION" != "$REQUIRED_BUNDLER_VERSION" ]; then # Simplified check, might need semver logic
        echo "Current Bundler version ($CURRENT_BUNDLER_VERSION) does not match target ($REQUIRED_BUNDLER_VERSION). Attempting to install specific version."
        gem install bundler -v "$REQUIRED_BUNDLER_VERSION" --no-document --user-install
    else
        echo "Current Bundler version is suitable."
    fi
  else
    echo "Bundler not found. Installing Bundler version $REQUIRED_BUNDLER_VERSION..."
    gem install bundler -v "$REQUIRED_BUNDLER_VERSION" --no-document --user-install
  fi
  
  echo "Verifying Bundler availability after install attempt..."
  if ! command -v bundle >/dev/null 2>&1; then
      echo "FATAL: Bundler command still not found after install attempt."
      exit 1
  fi
  echo "Bundler found at: $(which bundle)"
  echo "Bundler version: $(bundle --version)"
  
  echo "Configuring Bundler to install gems locally to vendor/bundle..."
  bundle config set --local path "vendor/bundle"
  
  echo "Running 'bundle install'..."
  # Use number of CPUs for parallel jobs, default to 4 if sysctl fails
  bundle install --jobs "$(sysctl -n hw.ncpu || echo 4)"
  
  echo "Running 'bundle exec pod install --repo-update'..."
  bundle exec pod install --repo-update --verbose
else
  echo "WARNING: Gemfile not found in $IOS_DIR. Attempting direct 'pod install'."
  echo "This is not recommended and may fail if system Ruby/CocoaPods versions are incompatible."
  
  if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods 'pod' command not found. Attempting 'gem install cocoapods --user-install'..."
    # This will likely install the latest CocoaPods, which might not be compatible with older Ruby.
    gem install cocoapods --no-document --user-install
    if ! command -v pod >/dev/null 2>&1; then
        echo "FATAL: 'pod' command still not found after attempting direct gem install."
        exit 1
    fi
  fi
  echo "CocoaPods 'pod' command found. Path: $(which pod)"
  echo "CocoaPods version: $(pod --version)"
  pod install --repo-update --verbose
fi

# --- 9. Final Success Message ---
echo "--- ci_post_clone.sh script completed successfully! ---"
echo "Timestamp: $(date)"

# Navigate back to the original directory from where the script was called if necessary
# cd "$CI_WORKSPACE/ios/ci_scripts/" # Or wherever Xcode Cloud expects to be

exit 0
