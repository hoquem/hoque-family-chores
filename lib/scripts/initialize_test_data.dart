import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/task.dart';

Future<void> main() async {
  try {
    logger.i("Starting test data initialization...");
    final firestore = FirebaseFirestore.instance;

    // Initialize test user
    final testUserId = 'OVGdeZJWqEQmx7ErJ3cu3dp5uTh1';
    final userDoc = await firestore.collection('users').doc(testUserId).get();
    if (!userDoc.exists) {
      await firestore.collection('users').doc(testUserId).set({
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
      logger.i("Created test user profile.");
    }

    // Initialize test family
    final familyId = 'ef37e597-5e7a-46b0-a00a-62147cb29c8c';
    final familyDoc =
        await firestore.collection('families').doc(familyId).get();
    if (!familyDoc.exists) {
      await firestore.collection('families').doc(familyId).set({
        'id': familyId,
        'name': 'Hoque Family',
        'creatorUserId': testUserId,
        'memberUserIds': [testUserId],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Created test family.");
    }

    // Initialize test tasks
    final tasksSnapshot = await firestore.collection('tasks').limit(1).get();
    if (tasksSnapshot.docs.isEmpty) {
      await firestore.collection('tasks').add({
        'title': 'Clean the kitchen',
        'description': 'Wash dishes, wipe counters, and sweep the floor',
        'points': 50,
        'status': TaskStatus.available.name,
        'familyId': familyId,
        'assigneeId': null,
        'createdBy': testUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      logger.i("Created test task.");
    }

    // Initialize test badges
    final badgesSnapshot = await firestore.collection('badges').limit(1).get();
    if (badgesSnapshot.docs.isEmpty) {
      await firestore.collection('badges').add({
        'name': 'First Task',
        'description': 'Complete your first task',
        'icon': 'first_task',
        'points': 100,
        'createdAt': FieldValue.serverTimestamp(),
      });
      logger.i("Created test badge.");
    }

    // Initialize test achievements
    final achievementsSnapshot =
        await firestore.collection('achievements').limit(1).get();
    if (achievementsSnapshot.docs.isEmpty) {
      await firestore.collection('achievements').add({
        'name': 'Task Master',
        'description': 'Complete 10 tasks',
        'icon': 'task_master',
        'points': 500,
        'createdAt': FieldValue.serverTimestamp(),
      });
      logger.i("Created test achievement.");
    }

    // Initialize test notifications
    final notificationsSnapshot =
        await firestore.collection('notifications').limit(1).get();
    if (notificationsSnapshot.docs.isEmpty) {
      await firestore.collection('notifications').add({
        'userId': testUserId,
        'title': 'Welcome!',
        'message': 'Welcome to Family Chores!',
        'type': 'welcome',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      logger.i("Created test notification.");
    }

    logger.i("Test data initialization completed successfully.");
  } catch (e, s) {
    logger.e("Error initializing test data: $e", error: e, stackTrace: s);
    rethrow;
  }
}
