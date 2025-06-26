# Firebase Data Management Scripts

This directory contains scripts for managing Firebase data, rules, and initialization for the Hoque Family Chores app.

## Quick Start

For a complete setup of your Firebase project (rules + data), run:

```bash
./scripts/firebase_data.sh setup-prod
```

This will:
- Deploy Firestore rules and indexes
- Initialize test data using the Node.js script
- Set up everything needed for the app to work

## Scripts Overview

### `firebase_data.sh` - Main Management Script

A comprehensive script that handles all Firebase operations:

#### Complete Setup Commands
- `setup-prod` - Complete production project setup (rules + data)
- `setup-test` - Complete test project setup (rules + data)

#### Individual Operations
- `deploy-rules` - Deploy only Firestore rules and indexes
- `init-data` - Initialize only Firestore data using Node.js script
- `create-test-data` - Create JSON files for manual import
- `export-current` - Export current project data
- `export-test` - Export test project data
- `export-prod` - Export production project data

#### Utility Commands
- `cleanup` - Clean up export files
- `setup-test-env` - Set up test environment
- `switch-to-test` - Switch to test project
- `switch-to-prod` - Switch to production project
- `status` - Show current project status
- `help` - Show help message

### `init_firestore.js` - Data Initialization Script

Node.js script that creates test data in Firestore using the Admin SDK.

**Features:**
- Creates family document
- Creates family member document
- Creates sample tasks
- Creates user profile in both `users` and `userProfiles` collections
- Uses proper string timestamps (compatible with Flutter app)

## Prerequisites

1. **Firebase CLI** installed and authenticated:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```

2. **Node.js and npm** installed

3. **Service Account Key** downloaded and placed at `scripts/serviceAccountKey.json`

## Usage Examples

### Complete Production Setup
```bash
./scripts/firebase_data.sh setup-prod
```

### Complete Test Setup
```bash
./scripts/firebase_data.sh setup-test
```

### Deploy Only Rules
```bash
./scripts/firebase_data.sh deploy-rules
```

### Initialize Only Data
```bash
./scripts/firebase_data.sh init-data
```

### Create Manual Import Files
```bash
./scripts/firebase_data.sh create-test-data
```

### Export Current Data
```bash
./scripts/firebase_data.sh export-current
```

## Configuration

The scripts use these default values (configurable in the script):

- **Production Project ID**: `hoque-family-chores-app`
- **Test Project ID**: `hoque-family-chores-test`
- **Family ID**: `ef37e597-5e7a-46b0-a00a-62147cb29c8c`
- **User ID**: `OVGdeZJWqEQmx7ErJ3cu3dp5uTh1`

## Data Structure

The scripts create the following Firestore structure:

```
families/
  └── ef37e597-5e7a-46b0-a00a-62147cb29c8c/
      ├── name: "Hoque Family"
      ├── description: "A happy family managing chores together"
      ├── creatorId: "OVGdeZJWqEQmx7ErJ3cu3dp5uTh1"
      └── memberIds: ["OVGdeZJWqEQmx7ErJ3cu3dp5uTh1"]

familyMembers/
  └── OVGdeZJWqEQmx7ErJ3cu3dp5uTh1/
      ├── userId: "OVGdeZJWqEQmx7ErJ3cu3dp5uTh1"
      ├── familyId: "ef37e597-5e7a-46b0-a00a-62147cb29c8c"
      ├── name: "Mahmud Hoque"
      ├── role: "parent"
      └── points: 0

tasks/
  ├── task-1/ (Clean the kitchen - 50 points)
  ├── task-2/ (Take out the trash - 25 points)
  └── task-3/ (Do laundry - 75 points)

users/
  └── OVGdeZJWqEQmx7ErJ3cu3dp5uTh1/
      ├── name: "Mahmud Hoque"
      ├── email: "mahmud@example.com"
      ├── member: {
      │   ├── familyId: "ef37e597-5e7a-46b0-a00a-62147cb29c8c"
      │   ├── name: "Mahmud Hoque"
      │   ├── role: "parent"
      │   └── points: 0
      │ }
      └── stats: { totalPoints: 0, tasksCompleted: 0, ... }

userProfiles/
  └── OVGdeZJWqEQmx7ErJ3cu3dp5uTh1/ (backup for compatibility)
```

## Troubleshooting

### Service Account Key Issues
If you get authentication errors:
1. Download your service account key from Google Cloud Console
2. Place it at `scripts/serviceAccountKey.json`
3. Ensure the key has the necessary permissions

### Firebase CLI Issues
If Firebase CLI commands fail:
1. Ensure you're logged in: `firebase login`
2. Check your project access: `firebase projects:list`
3. Switch to the correct project: `firebase use <project-id>`

### Node.js Issues
If Node.js script fails:
1. Ensure Node.js and npm are installed
2. Run `npm install` in the `scripts/` directory
3. Check that `scripts/serviceAccountKey.json` exists

## Manual Import (Alternative)

If you prefer to import data manually:

1. Run `./scripts/firebase_data.sh create-test-data`
2. Go to Firebase Console → Firestore Database
3. Import the JSON files from the `exports/` directory

## Security Rules

The Firestore rules ensure:
- Only authenticated users can access data
- Users can only access their family's data
- Family owners have additional permissions
- Proper validation of data structure

## Best Practices

1. **Use the comprehensive script** (`firebase_data.sh`) for most operations
2. **Test in test environment** before deploying to production
3. **Backup data** before major changes using export commands
4. **Keep service account key secure** and never commit it to version control
5. **Use separate projects** for development, testing, and production

## Script Architecture

The `firebase_data.sh` script provides a unified interface for all Firebase operations:

- ✅ **Environment validation** - Checks for required tools and credentials
- ✅ **Comprehensive logging** - Clear feedback for all operations
- ✅ **Error handling** - Graceful failure with helpful error messages
- ✅ **Modular design** - Individual commands for specific operations
- ✅ **Project management** - Easy switching between test and production
- ✅ **Data management** - Complete CRUD operations for Firestore data

## Current State & Cleanup Summary

### ✅ What's Been Cleaned Up

**Removed Old Scripts:**
- ❌ `setup_firestore.sh` - Replaced by comprehensive `firebase_data.sh`
- ❌ `initialize_test_data.dart` - Moved to Node.js for better reliability
- ❌ `initialize_firestore.dart` - Replaced by Admin SDK approach
- ❌ `initialize_firestore_command.dart` - No longer needed
- ❌ `initialize_family_firestore.dart` - Consolidated into main script
- ❌ `firestore_init_standalone.dart` - Replaced by Node.js script
- ❌ `check_firestore.dart` - Functionality moved to bash script
- ❌ `add_mock_tasks.dart` - Consolidated into main initialization

**Current Scripts Directory:**
```
scripts/
├── firebase_data.sh          # 🎯 Main comprehensive management script
├── init_firestore.js         # 📊 Node.js data initialization
├── package.json              # 📦 Node.js dependencies
├── package-lock.json         # 🔒 Locked dependency versions
├── serviceAccountKey.json    # 🔑 Firebase service account (gitignored)
├── README.md                 # 📖 This documentation
├── cleanup_branches.sh       # 🌿 Git branch management
└── resolve_pubspec_lock.sh   # 🔧 Flutter dependency resolution
```

### 🎯 Single Source of Truth

**For all Firebase operations, use:**
```bash
./scripts/firebase_data.sh [COMMAND]
```

**Key Commands:**
- `setup-prod` - Complete production setup
- `setup-test` - Complete test setup  
- `deploy-rules` - Deploy rules and indexes
- `init-data` - Initialize test data
- `status` - Check current project status

### 🚀 Benefits of the New Approach

1. **Unified Interface** - One script for all Firebase operations
2. **Better Error Handling** - Comprehensive validation and logging
3. **Environment Isolation** - Separate test and production projects
4. **Reliable Authentication** - Service account key approach
5. **Maintainable Code** - Clean separation of concerns
6. **Version Controlled** - All configuration in git
7. **Automated Setup** - Complete environment setup with one command

### 📋 Migration Complete

The migration from multiple scattered scripts to a single comprehensive solution is complete. All old scripts have been removed, and the new `firebase_data.sh` script provides all the functionality needed for Firebase management. 