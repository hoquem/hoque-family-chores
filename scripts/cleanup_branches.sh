#!/bin/bash
# cleanup_branches.sh
#
# A utility script to safely clean up Git branches
# Usage: ./scripts/cleanup_branches.sh [options]
#
# Make this script executable with: chmod +x scripts/cleanup_branches.sh

# Exit on error
set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default options
DELETE_LOCAL=false
DELETE_REMOTE=false
FORCE_DELETE=false
MERGED_ONLY=true
SHOW_ALL=false
SKIP_CONFIRMATION=false
SKIP_PROTECTED=true
DRY_RUN=false
VERBOSE=false
DEBUG=false

# Protected branches that should not be deleted
PROTECTED_BRANCHES=("main" "master" "develop" "staging" "production" "release")

# Debug function - only prints if DEBUG is true
debug() {
  if [[ "$DEBUG" == "true" ]]; then
    echo -e "${CYAN}[DEBUG]${NC} $*" >&2
  fi
}

# Function to display usage information
show_usage() {
  echo -e "${BOLD}Branch Cleanup Utility${NC}"
  echo
  echo -e "${BOLD}Usage:${NC} ./scripts/cleanup_branches.sh [options]"
  echo
  echo -e "${BOLD}Options:${NC}"
  echo "  -h, --help                 Show this help message"
  echo "  -l, --local                Delete local branches"
  echo "  -r, --remote               Delete remote branches"
  echo "  -a, --all                  Show/delete all branches (including unmerged)"
  echo "  -f, --force                Force delete unmerged branches"
  echo "  -y, --yes                  Skip confirmation prompts"
  echo "  --include-protected        Include protected branches in deletion list"
  echo "  --dry-run                  Show what would be deleted without actually deleting"
  echo "  -v, --verbose              Show additional information"
  echo "  --debug                    Show debug information (very verbose)"
  echo
  echo -e "${BOLD}Examples:${NC}"
  echo "  ./scripts/cleanup_branches.sh -l              # Delete merged local branches (interactive)"
  echo "  ./scripts/cleanup_branches.sh -r -a           # Delete all remote branches (interactive)"
  echo "  ./scripts/cleanup_branches.sh -l -r -y        # Delete all merged branches without confirmation"
  echo "  ./scripts/cleanup_branches.sh --dry-run -l    # Show which local branches would be deleted"
  echo
  echo -e "${YELLOW}Note:${NC} By default, the script will not delete protected branches (main, master, develop, etc.)"
  echo "      Use --include-protected to override this behavior."
  echo
}

# Error handling
handle_error() {
  local exit_code=$?
  echo -e "\n${RED}Error:${NC} Script failed with exit code $exit_code"
  echo "Command that failed: $BASH_COMMAND"
  exit $exit_code
}

# Set up error trap
trap handle_error ERR

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    -l|--local)
      DELETE_LOCAL=true
      ;;
    -r|--remote)
      DELETE_REMOTE=true
      ;;
    -a|--all)
      MERGED_ONLY=false
      SHOW_ALL=true
      ;;
    -f|--force)
      FORCE_DELETE=true
      ;;
    -y|--yes)
      SKIP_CONFIRMATION=true
      ;;
    --include-protected)
      SKIP_PROTECTED=false
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    -v|--verbose)
      VERBOSE=true
      ;;
    --debug)
      DEBUG=true
      VERBOSE=true
      # Enable command tracing for debug mode
      set -x
      ;;
    *)
      echo -e "${RED}Error:${NC} Unknown option: $1"
      show_usage
      exit 1
      ;;
  esac
  shift
done

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo -e "${RED}Error:${NC} Not inside a git repository!"
  exit 1
fi

# If neither local nor remote is specified, show usage
if [[ "$DELETE_LOCAL" == "false" && "$DELETE_REMOTE" == "false" ]]; then
  echo -e "${YELLOW}No action specified.${NC} Please use -l for local branches or -r for remote branches."
  show_usage
  exit 1
fi

# Function to check if a branch is protected
is_protected() {
  local branch_name=$1
  # Remove remote prefix if present (e.g., origin/main -> main)
  branch_name=${branch_name##*/}
  
  for protected in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$branch_name" == "$protected" ]]; then
      return 0 # True, branch is protected
    fi
  done
  return 1 # False, branch is not protected
}

# Function to get branch status (merged/not merged)
get_branch_status() {
  local branch=$1
  local is_local=$2
  local status=""
  local current_branch=$(git rev-parse --abbrev-ref HEAD)
  
  # Check if branch is merged
  if [[ "$is_local" == "true" ]]; then
    if git branch --merged | grep -q "^[* ] $branch$"; then
      status+="${GREEN}merged${NC}"
    else
      status+="${RED}not merged${NC}"
    fi
    
    # Check if branch is ahead/behind current branch
    if [[ "$branch" != "$current_branch" ]]; then
      local ahead_behind=$(git rev-list --left-right --count "$current_branch"..."$branch" 2>/dev/null || echo "0\t0")
      local behind=$(echo "$ahead_behind" | cut -f1 -d$'\t')
      local ahead=$(echo "$ahead_behind" | cut -f2 -d$'\t')
      
      if [[ "$ahead" != "0" ]]; then
        status+=" ${YELLOW}$ahead ahead${NC}"
      fi
      if [[ "$behind" != "0" ]]; then
        status+=" ${BLUE}$behind behind${NC}"
      fi
    fi
  else
    # For remote branches, check if merged to current branch
    local remote_branch=${branch#*/} # Remove the remote name prefix
    if git branch -r --merged | grep -q "^  $branch$"; then
      status+="${GREEN}merged${NC}"
    else
      status+="${RED}not merged${NC}"
    fi
  fi
  
  echo -e "$status"
}

# Function to get branch age
get_branch_age() {
  local branch=$1
  local is_local=$2
  local branch_ref=$branch
  
  if [[ "$is_local" == "false" ]]; then
    branch_ref=$branch
  fi
  
  # Get the last commit date
  local last_commit_date=$(git log -1 --format="%cr" "$branch_ref" 2>/dev/null || echo "unknown")
  echo "$last_commit_date"
}

# Function to delete branches with confirmation
delete_branches() {
  local branch_type=$1
  local is_local=$2
  shift 2
  local branches=("$@")
  
  debug "delete_branches called with branch_type=$branch_type, is_local=$is_local"
  debug "Number of branches passed: ${#branches[@]}"
  
  if [[ ${#branches[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No branches to delete.${NC}"
    return
  fi
  
  echo -e "\n${BOLD}${branch_type} branches to delete:${NC}"
  echo -e "${CYAN}----------------------------------------${NC}"
  
  local i=1
  local branches_to_delete=()
  
  for branch in "${branches[@]}"; do
    debug "Processing branch: '$branch'"
    
    # Skip empty branch names
    if [[ -z "$branch" ]]; then
      debug "Skipping empty branch name"
      continue
    }
    
    # Skip current branch
    if [[ "$is_local" == "true" && "$branch" == "$(git rev-parse --abbrev-ref HEAD)" ]]; then
      echo -e "${YELLOW}Skipping current branch:${NC} $branch"
      continue
    fi
    
    # Skip protected branches if SKIP_PROTECTED is true
    if [[ "$SKIP_PROTECTED" == "true" ]] && is_protected "$branch"; then
      if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${YELLOW}Skipping protected branch:${NC} $branch"
      fi
      continue
    fi
    
    # Get branch status
    local status=$(get_branch_status "$branch" "$is_local")
    local age=$(get_branch_age "$branch" "$is_local")
    
    # Skip unmerged branches if MERGED_ONLY is true
    if [[ "$MERGED_ONLY" == "true" && "$status" == *"not merged"* && "$FORCE_DELETE" == "false" ]]; then
      if [[ "$VERBOSE" == "true" || "$SHOW_ALL" == "true" ]]; then
        echo -e "${i}. ${branch} - ${status} - ${PURPLE}$age${NC} ${YELLOW}(skipped - not merged)${NC}"
      fi
      ((i++))
      continue
    fi
    
    echo -e "${i}. ${branch} - ${status} - ${PURPLE}$age${NC}"
    branches_to_delete+=("$branch")
    ((i++))
  done
  
  if [[ ${#branches_to_delete[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No branches match the criteria for deletion.${NC}"
    return
  fi
  
  # Ask for global confirmation if not skipping
  if [[ "$SKIP_CONFIRMATION" == "false" ]]; then
    echo
    read -p "Do you want to proceed with deletion? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${YELLOW}Operation cancelled.${NC}"
      return
    fi
  fi
  
  # Process each branch
  for branch in "${branches_to_delete[@]}"; do
    local delete_cmd=""
    local force_flag=""
    
    # Determine delete command and force flag
    if [[ "$is_local" == "true" ]]; then
      delete_cmd="git branch"
      if [[ "$FORCE_DELETE" == "true" ]]; then
        force_flag="-D"
      else
        force_flag="-d"
      fi
    else
      delete_cmd="git push origin --delete"
      # No force flag for remote deletion
    fi
    
    # Ask for confirmation for each branch if not skipping
    if [[ "$SKIP_CONFIRMATION" == "false" ]]; then
      echo
      read -p "Delete branch '$branch'? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping branch:${NC} $branch"
        continue
      fi
    fi
    
    # Execute delete command or show dry run
    if [[ "$DRY_RUN" == "true" ]]; then
      if [[ "$is_local" == "true" ]]; then
        echo -e "${CYAN}[DRY RUN]${NC} Would execute: $delete_cmd $force_flag \"$branch\""
      else
        echo -e "${CYAN}[DRY RUN]${NC} Would execute: $delete_cmd \"${branch#*/}\""
      fi
    else
      echo -e "${GREEN}Deleting branch:${NC} $branch"
      if [[ "$is_local" == "true" ]]; then
        $delete_cmd $force_flag "$branch" 2>/dev/null || {
          echo -e "${RED}Failed to delete branch:${NC} $branch"
          if [[ "$FORCE_DELETE" == "false" ]]; then
            echo -e "${YELLOW}Tip:${NC} Use -f/--force to force delete unmerged branches"
          fi
        }
      else
        # For remote branches, strip the remote name (origin/)
        $delete_cmd "${branch#*/}" 2>/dev/null || {
          echo -e "${RED}Failed to delete remote branch:${NC} $branch"
        }
      fi
    fi
  done
}

# Main execution

# Update remote references
echo -e "${BLUE}Fetching latest changes and pruning remote branches...${NC}"
git fetch --prune

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo -e "${BLUE}Current branch:${NC} ${BOLD}$CURRENT_BRANCH${NC}"

# Process local branches
if [[ "$DELETE_LOCAL" == "true" ]]; then
  debug "Processing local branches"
  
  # Get all local branches except current
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "\n${BLUE}Finding local branches...${NC}"
  fi
  
  # Use mapfile/readarray if available (bash 4+)
  if [[ $(bash --version | head -n1 | cut -d' ' -f4 | cut -d'.' -f1) -ge 4 ]]; then
    debug "Using mapfile for array creation (Bash 4+)"
    mapfile -t LOCAL_BRANCHES_ARRAY < <(git branch | grep -v "^\*" | sed 's/^[ \t]*//')
  else
    # Fallback for older bash versions
    debug "Using IFS-based array creation (Bash 3 compatibility)"
    IFS_OLD=$IFS
    IFS=$'\n'
    LOCAL_BRANCHES_ARRAY=($(git branch | grep -v "^\*" | sed 's/^[ \t]*//'))
    IFS=$IFS_OLD
  fi
  
  debug "Found ${#LOCAL_BRANCHES_ARRAY[@]} local branches"
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "Found ${#LOCAL_BRANCHES_ARRAY[@]} local branches"
  fi
  
  delete_branches "Local" true "${LOCAL_BRANCHES_ARRAY[@]}"
fi

# Process remote branches
if [[ "$DELETE_REMOTE" == "true" ]]; then
  debug "Processing remote branches"
  
  # Get all remote branches
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "\n${BLUE}Finding remote branches...${NC}"
  fi
  
  # Use mapfile/readarray if available (bash 4+)
  if [[ $(bash --version | head -n1 | cut -d' ' -f4 | cut -d'.' -f1) -ge 4 ]]; then
    debug "Using mapfile for array creation (Bash 4+)"
    mapfile -t REMOTE_BRANCHES_ARRAY < <(git branch -r | grep -v "HEAD" | sed 's/^[ \t]*//')
  else
    # Fallback for older bash versions
    debug "Using IFS-based array creation (Bash 3 compatibility)"
    IFS_OLD=$IFS
    IFS=$'\n'
    REMOTE_BRANCHES_ARRAY=($(git branch -r | grep -v "HEAD" | sed 's/^[ \t]*//'))
    IFS=$IFS_OLD
  fi
  
  debug "Found ${#REMOTE_BRANCHES_ARRAY[@]} remote branches"
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "Found ${#REMOTE_BRANCHES_ARRAY[@]} remote branches"
  fi
  
  # Filter out origin/main and similar protected branches
  if [[ "$SKIP_PROTECTED" == "true" ]]; then
    local FILTERED_BRANCHES=()
    for branch in "${REMOTE_BRANCHES_ARRAY[@]}"; do
      if ! is_protected "$branch"; then
        FILTERED_BRANCHES+=("$branch")
      elif [[ "$VERBOSE" == "true" ]]; then
        echo -e "${YELLOW}Skipping protected remote branch:${NC} $branch"
      fi
    done
    debug "After filtering, ${#FILTERED_BRANCHES[@]} remote branches remain"
    delete_branches "Remote" false "${FILTERED_BRANCHES[@]}"
  else
    delete_branches "Remote" false "${REMOTE_BRANCHES_ARRAY[@]}"
  fi
fi

echo -e "\n${GREEN}Branch cleanup completed!${NC}"

# Show remaining branches if verbose
if [[ "$VERBOSE" == "true" ]]; then
  echo -e "\n${BLUE}Remaining local branches:${NC}"
  git branch -v
  
  echo -e "\n${BLUE}Remaining remote branches:${NC}"
  git branch -r
fi

# If we're in debug mode, disable command tracing before exit
if [[ "$DEBUG" == "true" ]]; then
  set +x
fi

exit 0
