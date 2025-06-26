// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FirebaseTaskService implements TaskServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseTaskService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Helper to map QuerySnapshot to List<Task>
  List<Task> _mapQuerySnapshotToTaskList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  // Helper to map DocumentSnapshot to Task
  Task? _mapDocumentSnapshotToTask(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (doc.exists && doc.data() != null) {
      return Task.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  Stream<List<Task>> streamMyTasks({
    required String familyId,
    required String userId,
  }) {
    logger.d(
      "FirebaseTaskService: Streaming tasks for family $familyId and user $userId.",
    );
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('assigneeId', isEqualTo: userId)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList)
        .handleError((e, s) {
          logger.e(
            "FirebaseTaskService: Error streaming tasks: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Future<void> createTask({
    required String familyId,
    required Task task,
  }) async {
    logger.d(
      "FirebaseTaskService: Creating task ${task.id} for family $familyId.",
    );
    try {
      // Add timeout to Firestore operation
      await Future.any([
        _firestore
            .collection('families')
            .doc(familyId)
            .collection('tasks')
            .doc(task.id)
            .set(task.toFirestore()),
        Future.delayed(const Duration(seconds: 8)).then((_) {
          throw TimeoutException(
            'Firestore operation timed out after 8 seconds',
          );
        }),
      ]);
      logger.i('FirebaseTaskService: Task created successfully');
    } on TimeoutException catch (e, s) {
      logger.e(
        "FirebaseTaskService: Timeout creating task ${task.id} for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e(
        "FirebaseTaskService: Firebase error creating task ${task.id} for family $familyId: ${e.code} - ${e.message}",
        error: e,
        stackTrace: s,
      );
      rethrow;
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error creating task ${task.id} for family $familyId: $e",
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
    logger.d(
      "FirebaseTaskService: Updating task ${task.id} for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestore());
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error updating task ${task.id} for family $familyId: $e",
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
      "FirebaseTaskService: Updating status for task $taskId to ${newStatus.name} for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .update({'status': newStatus.name});
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error updating status for task $taskId: $e",
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
      "FirebaseTaskService: Assigning task $taskId to $assigneeId for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .update({
            'assigneeId': assigneeId,
            'status': TaskStatus.assigned.name,
          });
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error assigning task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d(
      "FirebaseTaskService: Deleting task $taskId for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error deleting task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<Task?> getTask({
    required String familyId,
    required String taskId,
  }) async {
    logger.d("FirebaseTaskService: Getting task $taskId for family $familyId.");
    try {
      final doc =
          await _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .doc(taskId)
              .get();
      return _mapDocumentSnapshotToTask(doc);
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error getting task $taskId for family $familyId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d(
      "FirebaseTaskService: Starting streamTasks for family ID: $familyId",
    );
    logger.d("FirebaseTaskService: Collection path: families/$familyId/tasks");

    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
          logger.d(
            "FirebaseTaskService: Received snapshot with ${snapshot.docs.length} documents",
          );

          // Log each document's data for debugging
          for (var doc in snapshot.docs) {
            logger.d("FirebaseTaskService: Document ${doc.id}: ${doc.data()}");
          }

          try {
            final tasks =
                snapshot.docs
                    .map(
                      (doc) => Task.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .where((task) => task != null)
                    .cast<Task>()
                    .toList();

            logger.d(
              "FirebaseTaskService: Successfully parsed ${tasks.length} tasks",
            );
            return tasks;
          } catch (e, s) {
            logger.e(
              "FirebaseTaskService: Error parsing tasks from Firestore: $e",
              error: e,
              stackTrace: s,
            );
            return <Task>[]; // Return empty list on error
          }
        })
        .handleError((e, s) {
          logger.e(
            "FirebaseTaskService: Error streaming tasks for family $familyId: $e",
            error: e,
            stackTrace: s,
          );
          return <Task>[]; // Return empty list on error
        });
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    logger.d(
      "FirebaseTaskService: Streaming available tasks for family $familyId.",
    );
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.available.name)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList)
        .handleError((e, s) {
          logger.e(
            "FirebaseTaskService: Error streaming available tasks for family $familyId: $e",
            error: e,
            stackTrace: s,
          );
        });
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    logger.d(
      "FirebaseTaskService: Streaming tasks by assignee $assigneeId for family $familyId.",
    );
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('assigneeId', isEqualTo: assigneeId)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList)
        .handleError((e, s) {
          logger.e(
            "FirebaseTaskService: Error streaming tasks by assignee $assigneeId for family $familyId: $e",
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
    logger.d(
      "FirebaseTaskService: Approving task $taskId for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .update({
            'status': TaskStatus.completed.name,
            'approvedBy': approverId, // Assuming you track who approved it
            'completedAt': FieldValue.serverTimestamp(), // Mark completion time
          });
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error approving task $taskId: $e",
        error: e,
        stackTrace: s,
      );
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
    logger.d(
      "FirebaseTaskService: Rejecting task $taskId for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .update({
            'status': TaskStatus.needsRevision.name,
            'rejectedBy': rejecterId, // Assuming you track who rejected it
            'revisionComments': comments, // Add comments for revision
          });
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error rejecting task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<void> claimTask({
    required String familyId,
    required String taskId,
    required String userId,
  }) async {
    logger.d(
      "FirebaseTaskService: Claiming task $taskId by user $userId for family $familyId.",
    );
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('tasks')
          .doc(taskId)
          .update({'assigneeId': userId, 'status': TaskStatus.assigned.name});
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error claiming task $taskId: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasks({
    required String familyId,
    required String userId,
    required TaskFilterType filter,
  }) async {
    logger.d(
      "FirebaseTaskService: Getting tasks for family $familyId and user $userId with filter $filter.",
    );
    try {
      final snapshot =
          await _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .get();
      final tasks =
          snapshot.docs
              .map(
                (doc) => Task.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
      switch (filter) {
        case TaskFilterType.all:
          return tasks;
        case TaskFilterType.myTasks:
          return tasks.where((task) => task.assigneeId == userId).toList();
        case TaskFilterType.available:
          return tasks
              .where((task) => task.status == TaskStatus.available)
              .toList();
        case TaskFilterType.completed:
          return tasks
              .where((task) => task.status == TaskStatus.completed)
              .toList();
      }
    } catch (e, s) {
      logger.e(
        "FirebaseTaskService: Error getting tasks: $e",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }
}
