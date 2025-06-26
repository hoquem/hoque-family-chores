#!/bin/bash

# Firebase Data Management Script
# This script manages test data, rules, and initialization for the Hoque Family Chores app

set -e  # Exit on any error

# Configuration
PROJECT_ID="hoque-family-chores-app"
TEST_PROJECT_ID="hoque-family-chores-test"  # Separate test project
FAMILY_ID="ef37e597-5e7a-46b0-a00a-62147cb29c8c"
USER_ID="OVGdeZJWqEQmx7ErJ3cu3dp5uTh1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Firebase CLI is installed
check_firebase_cli() {
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
}

# Check if user is logged in to Firebase
check_firebase_auth() {
    if ! firebase projects:list &> /dev/null; then
        log_error "Not authenticated with Firebase. Please login first:"
        echo "firebase login"
        exit 1
    fi
}

# Check if Node.js and npm are available
check_node_environment() {
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install it first."
        exit 1
    fi
}

# Check if service account key exists
check_service_account() {
    local key_path="scripts/serviceAccountKey.json"
    if [ ! -f "$key_path" ]; then
        log_error "Service account key not found at $key_path"
        log_info "Please download your service account key from Google Cloud Console and place it at $key_path"
        exit 1
    fi
}

# Deploy Firestore rules and indexes
deploy_firestore_config() {
    local project_id=$1
    log_info "Deploying Firestore rules and indexes to project: $project_id"
    
    # Switch to the project
    firebase use $project_id
    
    # Deploy rules
    if firebase deploy --only firestore:rules; then
        log_success "Firestore rules deployed successfully"
    else
        log_error "Failed to deploy Firestore rules"
        return 1
    fi
    
    # Deploy indexes
    if firebase deploy --only firestore:indexes; then
        log_success "Firestore indexes deployed successfully"
    else
        log_error "Failed to deploy Firestore indexes"
        return 1
    fi
}

# Initialize Firestore data using Node.js script
initialize_firestore_data() {
    local project_id=$1
    log_info "Initializing Firestore data for project: $project_id"
    
    # Check if Node.js script exists
    local script_path="scripts/init_firestore.js"
    if [ ! -f "$script_path" ]; then
        log_error "Firestore initialization script not found at $script_path"
        return 1
    fi
    
    # Check if package.json exists and install dependencies
    local package_path="scripts/package.json"
    if [ -f "$package_path" ]; then
        log_info "Installing Node.js dependencies..."
        cd scripts && npm install && cd ..
    fi
    
    # Set environment variable for service account
    export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/scripts/serviceAccountKey.json"
    
    # Run the initialization script
    if node "$script_path"; then
        log_success "Firestore data initialized successfully"
    else
        log_error "Failed to initialize Firestore data"
        return 1
    fi
}

# Complete setup for a project (rules + data)
setup_project() {
    local project_id=$1
    log_info "Setting up complete project: $project_id"
    
    # Deploy Firestore configuration
    deploy_firestore_config $project_id
    
    # Initialize data
    initialize_firestore_data $project_id
    
    log_success "Project $project_id setup completed successfully"
}

# Create test data JSON files for manual import
create_test_data_files() {
    log_info "Creating test data files..."
    
    # Create exports directory
    mkdir -p exports
    
    # Get current timestamp in ISO format (macOS compatible)
    CURRENT_TIME=$(date -u +%Y-%m-%dT%H:%M:%S.000Z)
    TOMORROW=$(date -u -v+1d +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d '+1 day' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000Z)
    DAY_AFTER_TOMORROW=$(date -u -v+2d +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d '+2 days' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000Z)
    THREE_DAYS=$(date -u -v+3d +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d '+3 days' +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S.000Z)
    
    # Create family document
    cat > exports/family.json << EOF
{
  "id": "$FAMILY_ID",
  "name": "Hoque Family",
  "description": "A happy family managing chores together",
  "creatorId": "$USER_ID",
  "memberIds": ["$USER_ID"],
  "createdAt": "$CURRENT_TIME",
  "updatedAt": "$CURRENT_TIME"
}
EOF

    # Create family member document
    cat > exports/family_member.json << EOF
{
  "id": "$USER_ID",
  "userId": "$USER_ID",
  "familyId": "$FAMILY_ID",
  "name": "Mahmud Hoque",
  "role": "parent",
  "points": 0,
  "joinedAt": "$CURRENT_TIME",
  "updatedAt": "$CURRENT_TIME"
}
EOF

    # Create sample tasks
    cat > exports/tasks.json << EOF
{
  "task-1": {
    "id": "task-1",
    "familyId": "$FAMILY_ID",
    "title": "Clean the kitchen",
    "description": "Wash dishes, wipe counters, and sweep the floor",
    "status": "available",
    "difficulty": "medium",
    "points": 50,
    "tags": ["cleaning", "kitchen"],
    "dueDate": "$TOMORROW",
    "createdAt": "$CURRENT_TIME"
  },
  "task-2": {
    "id": "task-2",
    "familyId": "$FAMILY_ID",
    "title": "Take out the trash",
    "description": "Empty all trash bins and take to the curb",
    "status": "available",
    "difficulty": "easy",
    "points": 25,
    "tags": ["cleaning", "trash"],
    "dueDate": "$DAY_AFTER_TOMORROW",
    "createdAt": "$CURRENT_TIME"
  },
  "task-3": {
    "id": "task-3",
    "familyId": "$FAMILY_ID",
    "title": "Do laundry",
    "description": "Wash, dry, and fold clothes",
    "status": "available",
    "difficulty": "hard",
    "points": 75,
    "tags": ["laundry", "clothes"],
    "dueDate": "$THREE_DAYS",
    "createdAt": "$CURRENT_TIME"
  }
}
EOF

    # Create user profile
    cat > exports/user_profile.json << EOF
{
  "id": "$USER_ID",
  "name": "Mahmud Hoque",
  "email": "mahmud@example.com",
  "createdAt": "$CURRENT_TIME",
  "updatedAt": "$CURRENT_TIME",
  "preferences": {
    "notifications": true,
    "theme": "light",
    "language": "en"
  },
  "stats": {
    "totalPoints": 0,
    "tasksCompleted": 0,
    "currentStreak": 0,
    "longestStreak": 0
  }
}
EOF

    log_success "Test data files created in exports/ directory"
    log_info "You can now manually import these files to Firestore using the Firebase Console"
}

# Export current Firestore data
export_current_data() {
    local project_id=$1
    local export_path=$2
    
    log_info "Exporting data from project: $project_id to $export_path"
    
    # Switch to the project
    firebase use $project_id
    
    # Create export directory
    mkdir -p $export_path
    
    # Export Firestore data (if supported)
    if firebase firestore:export $export_path 2>/dev/null; then
        log_success "Data exported successfully to $export_path"
    else
        log_warning "Firestore export not available. Please export manually from Firebase Console"
        log_info "Project: $project_id"
        log_info "Export path: $export_path"
    fi
}

# Clean up export files
cleanup_export_files() {
    log_info "Cleaning up export files..."
    rm -rf exports/
    log_success "Export files cleaned up"
}

# Show current project status
show_project_status() {
    log_info "Current Firebase project status:"
    firebase projects:list
    echo ""
    log_info "Current active project:"
    firebase use --add 2>/dev/null || firebase use
}

# Set up test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Check if test project exists
    if firebase projects:list | grep -q $TEST_PROJECT_ID; then
        log_info "Test project already exists: $TEST_PROJECT_ID"
    else
        log_info "Creating test project: $TEST_PROJECT_ID"
        firebase projects:create $TEST_PROJECT_ID --display-name "Hoque Family Chores Test"
    fi
    
    # Switch to test project
    firebase use $TEST_PROJECT_ID
    
    # Initialize Firestore if not already done
    if [ ! -f "firestore.rules" ]; then
        log_info "Initializing Firestore for test project..."
        firebase init firestore --project $TEST_PROJECT_ID --yes
    fi
    
    log_success "Test environment set up"
}

# Show usage
show_usage() {
    echo "Firebase Data Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup-prod          Complete setup for production project (rules + data)"
    echo "  setup-test          Complete setup for test project (rules + data)"
    echo "  deploy-rules        Deploy Firestore rules and indexes"
    echo "  init-data           Initialize Firestore data using Node.js script"
    echo "  create-test-data    Create test data JSON files for manual import"
    echo "  export-current      Export current Firestore data"
    echo "  export-test         Export data from test project"
    echo "  export-prod         Export data from production project"
    echo "  cleanup             Clean up export files"
    echo "  setup-test-env      Set up test environment (create test project)"
    echo "  switch-to-test      Switch to test project"
    echo "  switch-to-prod      Switch to production project"
    echo "  status              Show current project status"
    echo "  help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup-prod       # Complete production setup"
    echo "  $0 setup-test       # Complete test setup"
    echo "  $0 deploy-rules     # Deploy only rules and indexes"
    echo "  $0 init-data        # Initialize only data"
    echo ""
    echo "Note: For importing data manually, use the Firebase Console with the JSON files"
}

# Main script logic
main() {
    check_firebase_cli
    check_firebase_auth
    
    case "${1:-help}" in
        "setup-prod")
            check_node_environment
            check_service_account
            setup_project $PROJECT_ID
            ;;
        "setup-test")
            check_node_environment
            check_service_account
            setup_project $TEST_PROJECT_ID
            ;;
        "deploy-rules")
            deploy_firestore_config $(firebase use 2>/dev/null | grep -o '[a-zA-Z0-9-]*$')
            ;;
        "init-data")
            check_node_environment
            check_service_account
            initialize_firestore_data $(firebase use 2>/dev/null | grep -o '[a-zA-Z0-9-]*$')
            ;;
        "create-test-data")
            create_test_data_files
            ;;
        "export-current")
            export_current_data $(firebase use 2>/dev/null | grep -o '[a-zA-Z0-9-]*$') "./exports/current-$(date +%Y%m%d-%H%M%S)"
            ;;
        "export-test")
            export_current_data $TEST_PROJECT_ID "./exports/test-$(date +%Y%m%d-%H%M%S)"
            ;;
        "export-prod")
            export_current_data $PROJECT_ID "./exports/prod-$(date +%Y%m%d-%H%M%S)"
            ;;
        "cleanup")
            cleanup_export_files
            ;;
        "setup-test-env")
            setup_test_environment
            ;;
        "switch-to-test")
            firebase use $TEST_PROJECT_ID
            log_success "Switched to test project: $TEST_PROJECT_ID"
            ;;
        "switch-to-prod")
            firebase use $PROJECT_ID
            log_success "Switched to production project: $PROJECT_ID"
            ;;
        "status")
            show_project_status
            ;;
        "help"|*)
            show_usage
            ;;
    esac
}

# Run main function with all arguments
main "$@" 