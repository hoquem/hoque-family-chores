import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';

class FirebaseTaskService implements TaskServiceInterface {
  final FirebaseFirestore _firestore;
  final AppLogger _logger = AppLogger();

  FirebaseTaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Task>> getTasksForFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final snapshot =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .get();
        return snapshot.docs
            .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getTasksForFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Task>> getTasksForUser({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final snapshot =
            await _firestore
                .collectionGroup('tasks')
                .where('assigneeId', isEqualTo: userId)
                .get();
        return snapshot.docs
            .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getTasksForUser',
      context: {'userId': userId},
    );
  }

  @override
  Future<Task> createTask({required Task task}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final docRef =
            _firestore
                .collection('families')
                .doc(task.familyId)
                .collection('tasks')
                .doc();
        final taskWithId = task.copyWith(id: docRef.id);
        await docRef.set(taskWithId.toJson());
        return taskWithId;
      },
      operationName: 'createTask',
      context: {'familyId': task.familyId, 'taskId': task.id},
    );
  }

  @override
  Future<void> updateTask({required Task task}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(task.familyId)
            .collection('tasks')
            .doc(task.id)
            .update(task.toJson());
      },
      operationName: 'updateTask',
      context: {'familyId': task.familyId, 'taskId': task.id},
    );
  }

  @override
  Future<void> deleteTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .delete();
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'deleteTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> assignTask({required String taskId, required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'assigneeId': userId,
                  'status': TaskStatus.assigned.name,
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'assignTask',
      context: {'taskId': taskId, 'userId': userId},
    );
  }

  @override
  Future<void> unassignTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'assigneeId': null,
                  'status': TaskStatus.available.name,
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'unassignTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> completeTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'status': TaskStatus.pendingApproval.name,
                  'completedAt': FieldValue.serverTimestamp(),
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'completeTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> uncompleteTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'status': TaskStatus.assigned.name,
                  'completedAt': null,
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'uncompleteTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus status,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({'status': status.name});
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'updateTaskStatus',
      context: {'taskId': taskId, 'status': status.name},
    );
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final doc =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .get();
        if (!doc.exists) return null;
        return Task.fromJson({...?doc.data(), 'id': doc.id});
      },
      operationName: 'getTask',
      context: {'familyId': familyId, 'taskId': taskId},
    );
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => Task.fromJson({...doc.data(), 'id': doc.id}),
                        )
                        .toList(),
              ),
      streamName: 'streamTasks',
      context: {'familyId': familyId},
    );
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .where('status', isEqualTo: TaskStatus.available.name)
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => Task.fromJson({...doc.data(), 'id': doc.id}),
                        )
                        .toList(),
              ),
      streamName: 'streamAvailableTasks',
      context: {'familyId': familyId},
    );
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .where('assigneeId', isEqualTo: assigneeId)
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => Task.fromJson({...doc.data(), 'id': doc.id}),
                        )
                        .toList(),
              ),
      streamName: 'streamTasksByAssignee',
      context: {'familyId': familyId, 'assigneeId': assigneeId},
    );
  }

  @override
  Future<void> approveTask({required String taskId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'status': TaskStatus.completed.name,
                  'approvedAt': FieldValue.serverTimestamp(),
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'approveTask',
      context: {'taskId': taskId},
    );
  }

  @override
  Future<void> rejectTask({required String taskId, String? comments}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update({
                  'status': TaskStatus.needsRevision.name,
                  'rejectedAt': FieldValue.serverTimestamp(),
                  'rejectionComments': comments,
                });
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'rejectTask',
      context: {'taskId': taskId, 'comments': comments},
    );
  }

  @override
  Future<void> claimTask({required String taskId, required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // First get all families the user is a member of
        final familiesSnapshot = await _firestore.collection('families').get();

        for (final familyDoc in familiesSnapshot.docs) {
          final familyId = familyDoc.id;
          final task = await getTask(familyId: familyId, taskId: taskId);
          if (task != null) {
            // Get the user's family member data
            final userProfileDoc = await _firestore
                .collection('userProfiles')
                .doc(userId)
                .get();
            
            FamilyMember? assignedToMember;
            if (userProfileDoc.exists) {
              final userData = userProfileDoc.data()!;
              assignedToMember = FamilyMember.fromJson({
                'id': userId,
                'userId': userId,
                'familyId': familyId,
                'name': userData['name'] ?? 'Unknown User',
                'role': userData['role'] ?? 'child',
                'points': userData['points'] ?? 0,
                'joinedAt': userData['joinedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
                'updatedAt': userData['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
              });
            }

            final updateData = {
              'assignedTo': assignedToMember?.toJson(),
              'assigneeId': userId,
              'status': TaskStatus.assigned.name,
              'claimedAt': FieldValue.serverTimestamp(),
            };
            _logger.d('claimTask: Updating task $taskId in family $familyId for user $userId with data: '
              '${updateData.map((k, v) => MapEntry(k, v is Map ? v.toString() : v))}');
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('tasks')
                .doc(taskId)
                .update(updateData);
            _logger.d('claimTask: Update complete for task $taskId in family $familyId');
            return;
          }
        }
        throw Exception('Task not found');
      },
      operationName: 'claimTask',
      context: {'taskId': taskId, 'userId': userId},
    );
  }
}
