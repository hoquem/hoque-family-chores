import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/notification.dart'
    as app_notification;
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FirebaseDataService implements DataServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseDataService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // --- User Profile Methods ---
  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    logger.d("Streaming user profile with ID: $userId from Firestore.");
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          // Changed to 'users'
          if (doc.exists && doc.data() != null) {
            return UserProfile.fromSnapshot(doc);
          }
          return null;
        })
        .handleError((e, s) {
          logger.e(
            "Error streaming user profile $userId: $e",
            error: e,
            stackTrace: s,
          );
          // rethrow; // This line should NOT be here if handleError, only in try-catch
        });
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) async {
    logger.d("Getting user profile with ID: $userId from Firestore.");
    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(userId)
              .get(); // Changed to 'users'
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromSnapshot(doc);
      }
      return null;
    } catch (e, s) {
      logger.e(
        "Error getting user profile $userId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) async {
    logger.d("Creating user profile ${userProfile.id} in Firestore.");
    try {
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .set(userProfile.toJson()); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error creating user profile ${userProfile.id}: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile({required UserProfile user}) async {
    logger.d("Updating user profile ${user.id} in Firestore.");
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toJson(), SetOptions(merge: true)); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error updating user profile ${user.id}: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteUser({required String userId}) async {
    logger.d("Deleting user profile $userId from Firestore.");
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .delete(); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error deleting user profile $userId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateUserPoints({
    required String userId,
    required int points,
  }) async {
    logger.d("Updating points for user $userId by $points in Firestore.");
    try {
      await _firestore.collection('users').doc(userId).update({
        'totalPoints': FieldValue.increment(points),
      }); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error updating points for user $userId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // --- Family Methods ---
  @override
  Future<void> createFamily({required Family family}) async {
    logger.d("Creating family ${family.id} in Firestore.");
    try {
      await _firestore
          .collection('families')
          .doc(family.id)
          .set(family.toJson());
    } catch (e, s) {
      logger.e(
        "Error creating family ${family.id}: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<Family?> getFamily({required String familyId}) async {
    logger.d("Getting family with ID: $familyId from Firestore.");
    try {
      final doc = await _firestore.collection('families').doc(familyId).get();
      if (doc.exists && doc.data() != null) {
        return Family.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e, s) {
      logger.e("Error getting family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    logger.d(
      "Streaming family members for family ID: $familyId from Firestore.",
    );
    return _firestore
        .collection('users') // Changed to 'users'
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => FamilyMember.fromMap(doc.data()..['id'] = doc.id),
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "Error streaming family members for family $familyId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({
    required String familyId,
  }) async {
    logger.d("Getting family members for family ID: $familyId from Firestore.");
    try {
      final querySnapshot =
          await _firestore
              .collection('users') // Changed to 'users'
              .where('familyId', isEqualTo: familyId)
              .get();
      return querySnapshot.docs
          .map((doc) => FamilyMember.fromMap(doc.data()..['id'] = doc.id))
          .toList();
    } catch (e, s) {
      logger.e(
        "Error getting family members for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // --- Badge Related Methods ---
  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    logger.d("Streaming badges for user ID: $userId from Firestore.");
    return _firestore
        .collection('users') // Changed to 'users'
        .doc(userId)
        .collection('badges')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Badge.fromMap({...doc.data(), 'id': doc.id}))
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "Error streaming badges for user $userId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> awardBadge({
    required String userId,
    required Badge badge,
  }) async {
    logger.d("Awarding badge ${badge.id} to user $userId in Firestore.");
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badge.id)
          .set(badge.toJson(), SetOptions(merge: true)); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error awarding badge to user $userId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // --- Achievement Related Methods ---
  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    logger.d("Streaming achievements for user ID: $userId from Firestore.");
    return _firestore
        .collection('users') // Changed to 'users'
        .doc(userId)
        .collection('achievements')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Achievement.fromMap({...doc.data(), 'id': doc.id}),
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "Error streaming achievements for user $userId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) async {
    logger.d(
      "Granting achievement ${achievement.id} to user $userId in Firestore.",
    );
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set(
            achievement.toJson(),
            SetOptions(merge: true),
          ); // Changed to 'users'
    } catch (e, s) {
      logger.e(
        "Error granting achievement to user $userId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // --- Notification Related Methods ---
  @override
  Stream<List<app_notification.Notification>> streamNotifications({
    required String userId,
  }) {
    logger.d("Streaming notifications for user ID: $userId from Firestore.");
    return _firestore
        .collection('users') // Changed to 'users'
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => app_notification.Notification.fromMap({
                      ...doc.data(),
                      'id': doc.id,
                    }),
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "Error streaming notifications for user $userId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    logger.d("Marking notification $notificationId as read in Firestore.");
    try {
      // Adjusted to collectionGroup('notifications') as it's likely a subcollection
      // This part depends heavily on your actual Firestore structure.
      // If notifications are directly under 'users', it's `_firestore.collection('users').doc(userId).collection('notifications')`
      // If it's a top-level collection, it's `_firestore.collection('notifications')`
      // For now, retaining collectionGroup as it's more flexible.
      await _firestore
          .collectionGroup('notifications')
          .where(FieldPath.documentId, isEqualTo: notificationId)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              snapshot.docs.first.reference.update({'read': true});
            } else {
              logger.w(
                "Notification $notificationId not found to mark as read.",
              );
            }
          });
    } catch (e, s) {
      logger.e(
        "Error marking notification $notificationId as read: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  // --- Task-related methods (implementing DataServiceInterface) ---
  // Tasks rules defined for /tasks/{taskId} indicating a top-level collection.
  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("Streaming all tasks for family ID: $familyId from Firestore.");
    return _firestore
        .collection('tasks')
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
          logger.d("Received ${snapshot.docs.length} tasks from Firestore");
          return snapshot.docs
              .map(
                (doc) => Task.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        })
        .handleError((e, s) {
          logger.e(
            "Error streaming tasks for family $familyId: $e",
            error: e,
            stackTrace: s,
          );
          return <Task>[]; // Return empty list on error
        });
  }

  @override
  Future<Task?> getTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d("Getting task $taskId for family $familyId from Firestore.");
    try {
      final doc =
          await _firestore
              .collection('tasks')
              .doc(taskId)
              .get(); // Changed to 'tasks' (top-level)
      if (doc.exists && doc.data() != null) {
        final task = Task.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        return task;
      }
      return null;
    } catch (e, s) {
      logger.e(
        "Error getting task $taskId for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> createTask({
    required String familyId,
    required Task task,
  }) async {
    logger.d("Creating task ${task.id} for family $familyId in Firestore.");
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .set(task.toFirestore()); // Changed to 'tasks' (top-level)
    } catch (e, s) {
      logger.e(
        "Error creating task ${task.id} for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTask({
    required String familyId,
    required Task task,
  }) async {
    logger.d("Updating task ${task.id} for family $familyId in Firestore.");
    try {
      await _firestore
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore()); // Changed to 'tasks' (top-level)
    } catch (e, s) {
      logger.e(
        "Error updating task ${task.id} for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    logger.d(
      "Updating status for task $taskId to ${newStatus.name} for family $familyId in Firestore.",
    );
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'status': newStatus.name,
      }); // Changed to 'tasks' (top-level)
    } catch (e, s) {
      logger.e(
        "Error updating status for task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> assignTask({
    required String familyId,
    required String taskId,
    required String assigneeId,
  }) async {
    logger.d(
      "Assigning task $taskId to $assigneeId for family $familyId in Firestore.",
    );
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        // Changed to 'tasks' (top-level)
        'assigneeId': assigneeId,
        'status': TaskStatus.assigned.name,
      });
    } catch (e, s) {
      logger.e("Error assigning task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d("Deleting task $taskId for family $familyId from Firestore.");
    try {
      await _firestore
          .collection('tasks')
          .doc(taskId)
          .delete(); // Changed to 'tasks' (top-level)
    } catch (e, s) {
      logger.e("Error deleting task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    logger.d(
      "Streaming tasks assigned to $assigneeId in family $familyId from Firestore.",
    );
    return _firestore
        .collection('tasks') // Changed to 'tasks' (top-level)
        .where('familyId', isEqualTo: familyId)
        .where('assigneeId', isEqualTo: assigneeId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => Task.fromFirestore(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        )
        .handleError((e, s) {
          logger.e(
            "Error streaming tasks by assignee $assigneeId for family $familyId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> approveTask({
    required String familyId,
    required String taskId,
    required String approverId,
  }) async {
    logger.d("Approving task $taskId for family $familyId.");
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        // Changed to 'tasks' (top-level)
        'status': TaskStatus.completed.name,
        'approvedBy': approverId,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      logger.e("Error approving task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> rejectTask({
    required String familyId,
    required String taskId,
    required String rejecterId,
    String? comments,
  }) async {
    logger.d("Rejecting task $taskId for family $familyId.");
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        // Changed to 'tasks' (top-level)
        'status': TaskStatus.needsRevision.name,
        'rejectedBy': rejecterId,
        'revisionComments': comments,
      });
    } catch (e, s) {
      logger.e("Error rejecting task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> claimTask({
    required String familyId,
    required String taskId,
    required String userId,
  }) async {
    logger.d("Claiming task $taskId for family $familyId.");
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        // Changed to 'tasks' (top-level)
        'assigneeId': userId,
        'status': TaskStatus.assigned.name,
      });
    } catch (e, s) {
      logger.e("Error claiming task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }
}
