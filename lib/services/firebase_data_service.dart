import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/notification.dart' as app_notification;
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FirebaseDataService implements DataServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseDataService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- User Profile Methods ---
  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    logger.d("Streaming user profile with ID: $userId from Firestore.");
    return _firestore.collection('userProfiles').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    }).handleError((e, s) {
      logger.e("Error streaming user profile $userId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) async {
    logger.d("Getting user profile with ID: $userId from Firestore.");
    try {
      final doc = await _firestore.collection('userProfiles').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    } catch (e, s) {
      logger.e("Error getting user profile $userId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({required UserProfile user}) async {
    logger.d("Updating user profile ${user.id} in Firestore.");
    try {
      await _firestore.collection('userProfiles').doc(user.id).set(user.toJson(), SetOptions(merge: true));
    } catch (e, s) {
      logger.e("Error updating user profile ${user.id}: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteUser({required String userId}) async {
    logger.d("Deleting user profile $userId from Firestore.");
    try {
      await _firestore.collection('userProfiles').doc(userId).delete();
    } catch (e, s) {
      logger.e("Error deleting user profile $userId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateUserPoints({required String userId, required int points}) async {
    logger.d("Updating points for user $userId by $points in Firestore.");
    try {
      await _firestore.collection('userProfiles').doc(userId).update({'totalPoints': FieldValue.increment(points)});
    } catch (e, s) {
      logger.e("Error updating points for user $userId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Family Member Methods ---
  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    logger.d("Streaming family members for family ID: $familyId from Firestore.");
    return _firestore
        .collection('userProfiles')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => FamilyMember.fromMap(doc.data()..['id'] = doc.id)).toList())
        .handleError((e, s) {
      logger.e("Error streaming family members for family $familyId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({required String familyId}) async {
    logger.d("Getting family members for family ID: $familyId from Firestore.");
    try {
      final querySnapshot = await _firestore
          .collection('userProfiles')
          .where('familyId', isEqualTo: familyId)
          .get();
      return querySnapshot.docs.map((doc) => FamilyMember.fromMap(doc.data()..['id'] = doc.id)).toList();
    } catch (e, s) {
      logger.e("Error getting family members for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Badge Related Methods ---
  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    logger.d("Streaming badges for user ID: $userId from Firestore.");
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Badge.fromMap({...doc.data(), 'id': doc.id})).toList()) // Removed !
        .handleError((e, s) {
      logger.e("Error streaming badges for user $userId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<void> awardBadge({required String userId, required Badge badge}) async {
    logger.d("Awarding badge ${badge.id} to user $userId in Firestore.");
    try {
      await _firestore.collection('userProfiles').doc(userId).collection('badges').doc(badge.id).set(badge.toJson(), SetOptions(merge: true));
    } catch (e, s) {
      logger.e("Error awarding badge to user $userId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Achievement Related Methods ---
  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    logger.d("Streaming achievements for user ID: $userId from Firestore.");
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Achievement.fromMap({...doc.data(), 'id': doc.id})).toList()) // Removed !
        .handleError((e, s) {
      logger.e("Error streaming achievements for user $userId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<void> grantAchievement({required String userId, required Achievement achievement}) async {
    logger.d("Granting achievement ${achievement.id} to user $userId in Firestore.");
    try {
      await _firestore.collection('userProfiles').doc(userId).collection('achievements').doc(achievement.id).set(achievement.toJson(), SetOptions(merge: true));
    } catch (e, s) {
      logger.e("Error granting achievement to user $userId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Notification Related Methods ---
  @override
  Stream<List<app_notification.Notification>> streamNotifications({required String userId}) {
    logger.d("Streaming notifications for user ID: $userId from Firestore.");
    return _firestore
        .collection('userProfiles')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => app_notification.Notification.fromMap({...doc.data(), 'id': doc.id})).toList()) // Removed !
        .handleError((e, s) {
      logger.e("Error streaming notifications for user $userId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    logger.d("Marking notification $notificationId as read in Firestore.");
    try {
      await _firestore
          .collectionGroup('notifications')
          .where(FieldPath.documentId, isEqualTo: notificationId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          snapshot.docs.first.reference.update({'read': true});
        } else {
          logger.w("Notification $notificationId not found to mark as read.");
        }
      });
    } catch (e, s) {
      logger.e("Error marking notification $notificationId as read: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- Task-related methods (implementing DataServiceInterface) ---
  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("Streaming all tasks for family ID: $familyId from Firestore.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList())
        .handleError((e, s) {
      logger.e("Error streaming tasks for family $familyId: $e", error: e, stackTrace: s);
    });
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) async {
    logger.d("Getting task $taskId for family $familyId from Firestore.");
    try {
      final doc = await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).get();
      if (doc.exists && doc.data() != null) {
        return Task.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e, s) {
      logger.e("Error getting task $taskId for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> createTask({required String familyId, required Task task}) async {
    logger.d("Creating task ${task.id} for family $familyId in Firestore.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(task.id).set(task.toFirestore());
    } catch (e, s) {
      logger.e("Error creating task ${task.id} for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateTask({required String familyId, required Task task}) async {
    logger.d("Updating task ${task.id} for family $familyId in Firestore.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(task.id).update(task.toFirestore());
    } catch (e, s) {
      logger.e("Error updating task ${task.id} for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}) async {
    logger.d("Updating status for task $taskId to ${newStatus.name} for family $familyId in Firestore.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({'status': newStatus.name});
    } catch (e, s) {
      logger.e("Error updating status for task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId}) async {
    logger.d("Assigning task $taskId to $assigneeId for family $familyId in Firestore.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({
        'assigneeId': assigneeId,
        'status': TaskStatus.assigned.name,
      });
    } catch (e, s) {
      logger.e("Error assigning task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask({required String familyId, required String taskId}) async {
    logger.d("Deleting task $taskId for family $familyId from Firestore.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).delete();
    } catch (e, s) {
      logger.e("Error deleting task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}) {
    logger.d("Streaming tasks assigned to $assigneeId in family $familyId from Firestore.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('assigneeId', isEqualTo: assigneeId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList())
        .handleError((e, s) {
      logger.e("Error streaming tasks by assignee $assigneeId for family $familyId: $e", error: e, stackTrace: s);
    });
  }
}