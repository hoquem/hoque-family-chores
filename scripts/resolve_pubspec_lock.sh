#!/bin/bash
# resolve_pubspec_lock.sh
# 
# A utility script to help resolve merge conflicts in pubspec.lock files
# Usage: ./scripts/resolve_pubspec_lock.sh [ours|theirs]
#
# After running this script, you should review and commit the changes.
# 
# Note: Make this script executable with: chmod +x scripts/resolve_pubspec_lock.sh

set -e # Exit immediately if a command exits with non-zero status

# Display colorful messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display usage instructions
show_usage() {
  echo -e "${YELLOW}Usage:${NC} ./scripts/resolve_pubspec_lock.sh [ours|theirs]"
  echo
  echo "Arguments:"
  echo "  ours    - Keep our version of pubspec.lock (the current branch)"
  echo "  theirs  - Use their version of pubspec.lock (the incoming branch)"
  echo
  echo "Example:"
  echo "  ./scripts/resolve_pubspec_lock.sh ours"
  echo
}

# Check if pubspec.lock exists
if [ ! -f "pubspec.lock" ]; then
  echo -e "${RED}Error:${NC} pubspec.lock file not found!"
  echo "Make sure you're running this script from the root of your Flutter project."
  exit 1
fi

# Check if git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${RED}Error:${NC} Not inside a git repository!"
  exit 1
fi

# Validate argument
if [ "$#" -ne 1 ]; then
  echo -e "${RED}Error:${NC} Incorrect number of arguments."
  show_usage
  exit 1
fi

CHOICE=$(echo "$1" | tr '[:upper:]' '[:lower:]')
if [ "$CHOICE" != "ours" ] && [ "$CHOICE" != "theirs" ]; then
  echo -e "${RED}Error:${NC} Invalid argument: $1"
  show_usage
  exit 1
fi

# Check if pubspec.lock has conflicts
if ! grep -q "<<<<<<< HEAD" pubspec.lock && ! grep -q "=======" pubspec.lock && ! grep -q ">>>>>>> " pubspec.lock; then
  echo -e "${YELLOW}Warning:${NC} No merge conflicts detected in pubspec.lock."
  echo "If you're sure there are conflicts, they might be in a different format."
  echo "Continue anyway? (y/n)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
  fi
fi

echo -e "${YELLOW}Resolving pubspec.lock conflicts using '$CHOICE' version...${NC}"

# Use git checkout to resolve the conflict
if [ "$CHOICE" = "ours" ]; then
  git checkout --ours pubspec.lock
  echo -e "${GREEN}✓${NC} Using OUR version of pubspec.lock (current branch)"
else
  git checkout --theirs pubspec.lock
  echo -e "${GREEN}✓${NC} Using THEIR version of pubspec.lock (incoming branch)"
fi

# Run flutter pub get to regenerate dependencies
echo -e "${YELLOW}Running flutter pub get to ensure consistency...${NC}"
flutter pub get
echo -e "${GREEN}✓${NC} Dependencies updated successfully"

# Stage the changes
git add pubspec.lock
echo -e "${GREEN}✓${NC} Changes to pubspec.lock have been staged"

echo
echo -e "${GREEN}Conflict resolution complete!${NC}"
echo "Next steps:"
echo "1. Review the changes (git diff --cached)"
echo "2. Continue with your merge or rebase"
echo "3. Commit the resolved conflict when ready"
echo

exit 0
