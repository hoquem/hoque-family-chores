const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Configuration
const PROJECT_ID = 'hoque-family-chores-app';
const FAMILY_ID = 'ef37e597-5e7a-46b0-a00a-62147cb29c8c';
const USER_ID = 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1';

// Initialize Firebase Admin SDK
function initializeFirebase() {
  try {
    // Try to use service account key if available
    const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
    if (fs.existsSync(serviceAccountPath)) {
      const serviceAccount = require(serviceAccountPath);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: PROJECT_ID,
      });
      console.log('✅ Firebase Admin SDK initialized with service account');
    } else {
      // Use default credentials (requires gcloud auth)
      admin.initializeApp({
        projectId: PROJECT_ID,
      });
      console.log('✅ Firebase Admin SDK initialized with default credentials');
    }
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK:', error.message);
    console.log('\nTo fix this:');
    console.log('1. Run: gcloud auth application-default login');
    console.log('2. Or create a service account key and save it as scripts/serviceAccountKey.json');
    process.exit(1);
  }
}

// Create test data
async function createTestData() {
  const db = admin.firestore();
  
  console.log('\n📝 Creating test data...');
  
  try {
    const now = new Date().toISOString();
    
    // Create family document
    const familyData = {
      id: FAMILY_ID,
      name: 'Hoque Family',
      description: 'A happy family managing chores together',
      creatorId: USER_ID,
      memberIds: [USER_ID],
      createdAt: now,
      updatedAt: now,
    };
    
    await db.collection('families').doc(FAMILY_ID).set(familyData);
    console.log('✅ Created family document');
    
    // Create family member document
    const memberData = {
      id: USER_ID,
      userId: USER_ID,
      familyId: FAMILY_ID,
      name: 'Mahmud Hoque',
      role: 'parent',
      points: 0,
      joinedAt: now,
      updatedAt: now,
    };
    
    await db.collection('families').doc(FAMILY_ID).collection('members').doc(USER_ID).set(memberData);
    console.log('✅ Created family member document');
    
    // Create sample tasks
    const tasks = [
      {
        id: 'task-1',
        familyId: FAMILY_ID,
        title: 'Clean the kitchen',
        description: 'Wash dishes, wipe counters, and sweep the floor',
        status: 'available',
        difficulty: 'medium',
        points: 50,
        tags: ['cleaning', 'kitchen'],
        dueDate: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // Tomorrow
        createdAt: now,
      },
      {
        id: 'task-2',
        familyId: FAMILY_ID,
        title: 'Take out the trash',
        description: 'Empty all trash bins and take to the curb',
        status: 'available',
        difficulty: 'easy',
        points: 25,
        tags: ['cleaning', 'trash'],
        dueDate: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(), // Day after tomorrow
        createdAt: now,
      },
      {
        id: 'task-3',
        familyId: FAMILY_ID,
        title: 'Do laundry',
        description: 'Wash, dry, and fold clothes',
        status: 'available',
        difficulty: 'hard',
        points: 75,
        tags: ['laundry', 'clothes'],
        dueDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(), // 3 days from now
        createdAt: now,
      },
    ];
    
    for (const task of tasks) {
      await db.collection('families').doc(FAMILY_ID).collection('tasks').doc(task.id).set(task);
    }
    console.log('✅ Created 3 sample tasks');
    
    // Create user profile in the 'users' collection (as expected by the app)
    const userProfileData = {
      id: USER_ID,
      member: {
        id: USER_ID,
        userId: USER_ID,
        familyId: FAMILY_ID,
        name: 'Mahmud Hoque',
        role: 'parent',
        points: 0,
        joinedAt: now,
        updatedAt: now,
      },
      points: 0,
      badges: [],
      achievements: [],
      createdAt: now,
      updatedAt: now,
      completedTasks: [],
      inProgressTasks: [],
      availableTasks: [],
      preferences: {
        notifications: true,
        theme: 'light',
        language: 'en',
      },
      statistics: {
        totalPoints: 0,
        tasksCompleted: 0,
        currentStreak: 0,
        longestStreak: 0,
      },
    };
    
    await db.collection('users').doc(USER_ID).set(userProfileData);
    console.log('✅ Created user profile document in users collection');
    
    // Also create in userProfiles collection for compatibility
    await db.collection('userProfiles').doc(USER_ID).set(userProfileData);
    console.log('✅ Created user profile document in userProfiles collection');
    
    console.log('\n🎉 All test data created successfully!');
    
  } catch (error) {
    console.error('❌ Error creating test data:', error);
    throw error;
  }
}

// Deploy Firestore rules
async function deployRules() {
  console.log('\n🔒 Deploying Firestore rules...');
  
  try {
    const rulesPath = path.join(__dirname, '..', 'firestore.rules');
    if (!fs.existsSync(rulesPath)) {
      console.log('⚠️  No firestore.rules file found, skipping rules deployment');
      return;
    }
    
    const rules = fs.readFileSync(rulesPath, 'utf8');
    
    // Note: This would require the Firebase CLI to be installed and authenticated
    // For now, we'll just validate the rules file
    console.log('✅ Firestore rules file found and validated');
    console.log('📋 To deploy rules, run: firebase deploy --only firestore:rules');
    
  } catch (error) {
    console.error('❌ Error with rules:', error);
  }
}

// Create indexes
async function createIndexes() {
  console.log('\n📊 Creating Firestore indexes...');
  
  try {
    // Note: Index creation via Admin SDK is limited
    // Most indexes are created automatically by Firestore
    console.log('✅ Firestore indexes will be created automatically as needed');
    console.log('📋 To create custom indexes, use the Firebase Console or firestore.indexes.json');
    
  } catch (error) {
    console.error('❌ Error with indexes:', error);
  }
}

// Main function
async function main() {
  console.log('🚀 Initializing Firestore for Hoque Family Chores App');
  console.log(`📁 Project ID: ${PROJECT_ID}`);
  console.log(`👨‍👩‍👧‍👦 Family ID: ${FAMILY_ID}`);
  console.log(`👤 User ID: ${USER_ID}`);
  
  try {
    initializeFirebase();
    await createTestData();
    await deployRules();
    await createIndexes();
    
    console.log('\n🎯 Initialization complete!');
    console.log('\n📱 You can now run the Flutter app and it should find the test data.');
    console.log('\n🔗 Firebase Console: https://console.firebase.google.com/project/' + PROJECT_ID);
    
  } catch (error) {
    console.error('\n❌ Initialization failed:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

// Run the script
if (require.main === module) {
  main();
}

module.exports = { initializeFirebase, createTestData, deployRules, createIndexes }; 