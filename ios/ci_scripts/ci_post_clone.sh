 ```bash
#!/bin/sh
echo "--- ci_post_clone.sh SCRIPT IS STARTING - NEW BUILD TEST ---" 
# ... rest of your script ...
# This script is executed in the cloned repository root by default.

echo "--- Starting CI Script: $(basename "$0") ---"

# Optional: Set exit on error
set -e

echo "Fetching Flutter version specified in Xcode Cloud workflow (or default)..."
# Xcode Cloud often provides the Flutter SDK. If you need a specific version not available,
# you might need to install it manually here (e.g., using FVM or git clone flutter).
# For now, assume Flutter is available.

echo "Running flutter doctor..."
flutter doctor # Good for logging, helps ensure Flutter environment is okay

echo "Running flutter pub get..."
flutter pub get

echo "Navigating to iOS directory: $CI_PRIMARY_REPOSITORY_PATH/ios"
# $CI_PRIMARY_REPOSITORY_PATH is an environment variable Xcode Cloud provides,
# pointing to the root of your cloned primary repository.
# Or, if your script is at the root, 'cd ios' is simpler.
cd "$CI_PRIMARY_REPOSITORY_PATH/ios" 
# If the above doesn't work, and your script is at the root with pubspec.yaml, simply use:
# cd ios

echo "Running pod install in $(pwd)..."
# Using --repo-update is good practice in CI to ensure you have the latest pod specs
pod install --repo-update 
# If building on Apple Silicon runners and encountering specific pod issues,
# you might consider 'arch -x86_64 pod install --repo-update',
# but usually 'pod install' suffices in Xcode Cloud.

echo "--- CI Script Finished ---"

# Important: The script must exit with 0 for success
exit 0
```