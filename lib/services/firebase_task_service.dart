import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';

class FirebaseTaskService implements TaskServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseTaskService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Helper to map QuerySnapshot to List<Task>
  List<Task> _mapQuerySnapshotToTaskList(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map((doc) => Task.fromFirestore(doc.data(), doc.id)).toList(); // Corrected: fromFirestore
  }

  // Helper to map DocumentSnapshot to Task
  Task? _mapDocumentSnapshotToTask(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (doc.exists && doc.data() != null) {
      return Task.fromFirestore(doc.data()!, doc.id); // Corrected: fromFirestore
    }
    return null;
  }

  @override
  Stream<List<Task>> streamMyTasks({required String familyId, required String userId}) {
    logger.d("FirebaseTaskService: Streaming tasks for family $familyId and user $userId.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('assigneeId', isEqualTo: userId)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList)
        .handleError((e, s) {
          logger.e("FirebaseTaskService: Error streaming tasks: $e", error: e, stackTrace: s);
        });
  }

  @override
  Future<void> createTask({required String familyId, required Task task}) async {
    logger.d("FirebaseTaskService: Creating task ${task.id} for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(task.id).set(task.toFirestore());
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error creating task ${task.id} for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateTask({required String familyId, required Task task}) async {
    logger.d("FirebaseTaskService: Updating task ${task.id} for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(task.id).update(task.toFirestore());
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error updating task ${task.id} for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}) async {
    logger.d("FirebaseTaskService: Updating status for task $taskId to ${newStatus.name} for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({'status': newStatus.name});
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error updating status for task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId}) async {
    logger.d("FirebaseTaskService: Assigning task $taskId to $assigneeId for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({
        'assigneeId': assigneeId,
        'status': TaskStatus.assigned.name,
      });
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error assigning task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteTask({required String familyId, required String taskId}) async {
    logger.d("FirebaseTaskService: Deleting task $taskId for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).delete();
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error deleting task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) async {
    logger.d("FirebaseTaskService: Getting task $taskId for family $familyId.");
    try {
      final doc = await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).get();
      return _mapDocumentSnapshotToTask(doc); // Corrected: use helper
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error getting task $taskId for family $familyId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("FirebaseTaskService: Streaming all tasks for family ID: $familyId.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .snapshots()
        .map(_mapQuerySnapshotToTaskList) // Corrected: use helper
        .handleError((e, s) {
          logger.e("FirebaseTaskService: Error streaming tasks for family $familyId: $e", error: e, stackTrace: s);
        });
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    logger.d("FirebaseTaskService: Streaming available tasks for family $familyId.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.available.name)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList) // Corrected: use helper
        .handleError((e, s) {
          logger.e("FirebaseTaskService: Error streaming available tasks for family $familyId: $e", error: e, stackTrace: s);
        });
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}) {
    logger.d("FirebaseTaskService: Streaming tasks by assignee $assigneeId for family $familyId.");
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('tasks')
        .where('assigneeId', isEqualTo: assigneeId)
        .snapshots()
        .map(_mapQuerySnapshotToTaskList) // Corrected: use helper
        .handleError((e, s) {
          logger.e("FirebaseTaskService: Error streaming tasks by assignee $assigneeId for family $familyId: $e", error: e, stackTrace: s);
        });
  }

  @override
  Future<void> approveTask({required String familyId, required String taskId, required String approverId}) async {
    logger.d("FirebaseTaskService: Approving task $taskId for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({
        'status': TaskStatus.completed.name,
        'approvedBy': approverId, // Assuming you track who approved it
        'completedAt': FieldValue.serverTimestamp(), // Mark completion time
      });
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error approving task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> rejectTask({required String familyId, required String taskId, required String rejecterId, String? comments}) async {
    logger.d("FirebaseTaskService: Rejecting task $taskId for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({
        'status': TaskStatus.needsRevision.name,
        'rejectedBy': rejecterId, // Assuming you track who rejected it
        'revisionComments': comments, // Add comments for revision
      });
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error rejecting task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> claimTask({required String familyId, required String taskId, required String userId}) async {
    logger.d("FirebaseTaskService: Claiming task $taskId by user $userId for family $familyId.");
    try {
      await _firestore.collection('families').doc(familyId).collection('tasks').doc(taskId).update({
        'assigneeId': userId,
        'status': TaskStatus.assigned.name,
      });
    } catch (e, s) {
      logger.e("FirebaseTaskService: Error claiming task $taskId: $e", error: e, stackTrace: s);
      rethrow;
    }
  }
}