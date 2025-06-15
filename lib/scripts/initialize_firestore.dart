import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirestoreInitializer {
  final FirebaseFirestore _firestore;
  final _logger = AppLogger();

  FirestoreInitializer({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initializeCollections() async {
    try {
      _logger.i("Starting Firestore collections initialization...");

      // Initialize users collection
      await _initializeUsersCollection();

      // Initialize families collection
      await _initializeFamiliesCollection();

      // Initialize tasks collection
      await _initializeTasksCollection();

      // Initialize badges collection
      await _initializeBadgesCollection();

      // Initialize achievements collection
      await _initializeAchievementsCollection();

      // Initialize notifications collection
      await _initializeNotificationsCollection();

      _logger.i("Firestore collections initialization completed successfully.");
    } catch (e, s) {
      _logger.e(
        "Error initializing Firestore collections: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  Future<void> _initializeUsersCollection() async {
    _logger.d("Initializing users collection...");
    // Create a test user if it doesn't exist
    final testUserId = 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1'; // Your test user ID
    final userDoc = await _firestore.collection('users').doc(testUserId).get();

    if (!userDoc.exists) {
      await _firestore.collection('users').doc(testUserId).set({
        'id': testUserId,
        'name': 'Mahmudul Hoque',
        'email': 'mahmudul.hoque@gmail.com',
        'familyId': 'ef37e597-5e7a-46b0-a00a-62147cb29c8c',
        'role': FamilyRole.parent.name,
        'totalPoints': 0,
        'currentLevel': 1,
        'completedTasks': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'unlockedBadges': [],
        'redeemedRewards': [],
        'achievements': [],
        'lastTaskCompletedAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test user profile.");
    }
  }

  Future<void> _initializeFamiliesCollection() async {
    _logger.d("Initializing families collection...");
    final familyId = 'ef37e597-5e7a-46b0-a00a-62147cb29c8c';
    final familyDoc =
        await _firestore.collection('families').doc(familyId).get();

    if (!familyDoc.exists) {
      await _firestore.collection('families').doc(familyId).set({
        'id': familyId,
        'name': 'Hoque Family',
        'creatorUserId': 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1',
        'memberUserIds': ['OVGdeZJWqEQmx7ErJ3cu3dp5uTh1'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test family.");
    }
  }

  Future<void> _initializeTasksCollection() async {
    _logger.d("Initializing tasks collection...");
    // Create a test task if none exist
    final tasksSnapshot = await _firestore.collection('tasks').limit(1).get();

    if (tasksSnapshot.docs.isEmpty) {
      await _firestore.collection('tasks').add({
        'title': 'Clean the kitchen',
        'description': 'Wash dishes, wipe counters, and sweep the floor',
        'points': 50,
        'status': TaskStatus.available.name,
        'familyId': 'ef37e597-5e7a-46b0-a00a-62147cb29c8c',
        'assigneeId': null,
        'createdBy': 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test task.");
    }
  }

  Future<void> _initializeBadgesCollection() async {
    _logger.d("Initializing badges collection...");
    // Create some basic badges if none exist
    final badgesSnapshot = await _firestore.collection('badges').limit(1).get();

    if (badgesSnapshot.docs.isEmpty) {
      await _firestore.collection('badges').add({
        'name': 'First Task',
        'description': 'Complete your first task',
        'icon': 'first_task',
        'points': 100,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test badge.");
    }
  }

  Future<void> _initializeAchievementsCollection() async {
    _logger.d("Initializing achievements collection...");
    // Create some basic achievements if none exist
    final achievementsSnapshot =
        await _firestore.collection('achievements').limit(1).get();

    if (achievementsSnapshot.docs.isEmpty) {
      await _firestore.collection('achievements').add({
        'name': 'Task Master',
        'description': 'Complete 10 tasks',
        'icon': 'task_master',
        'points': 500,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test achievement.");
    }
  }

  Future<void> _initializeNotificationsCollection() async {
    _logger.d("Initializing notifications collection...");
    // Create a test notification if none exist
    final notificationsSnapshot =
        await _firestore.collection('notifications').limit(1).get();

    if (notificationsSnapshot.docs.isEmpty) {
      await _firestore.collection('notifications').add({
        'userId': 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1',
        'title': 'Welcome!',
        'message': 'Welcome to Family Chores!',
        'type': 'welcome',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _logger.i("Created test notification.");
    }
  }
}
