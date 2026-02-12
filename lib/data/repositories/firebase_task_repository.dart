import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/entities/task.dart';
import '../../domain/value_objects/task_id.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of TaskRepository
class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirebaseTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Task>> getTasksForFamily(FamilyId familyId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToTask(doc.data(), doc.id, familyId))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get tasks for family: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Future<List<Task>> getTasksForUser(UserId userId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('tasks')
          .where('assignedToId', isEqualTo: userId.value)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToTask(doc.data(), doc.id, FamilyId(doc.reference.parent.parent!.id)))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get tasks for user: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Future<Task> createTask(Task task) async {
    try {
      final docRef = _firestore
          .collection('families')
          .doc(task.familyId.value)
          .collection('tasks')
          .doc();

      final taskWithId = task.copyWith(id: TaskId(docRef.id));
      await docRef.set(_mapTaskToFirestore(taskWithId));
      return taskWithId;
    } catch (e) {
      throw ServerException('Failed to create task: $e', code: 'TASK_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateTask(Task task) async {
    try {
      await _firestore
          .collection('families')
          .doc(task.familyId.value)
          .collection('tasks')
          .doc(task.id.value)
          .update(_mapTaskToFirestore(task));
    } catch (e) {
      throw ServerException('Failed to update task: $e', code: 'TASK_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteTask(TaskId taskId) async {
    try {
      // Find the task first to get its family ID
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .delete();
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete task: $e', code: 'TASK_DELETE_ERROR');
    }
  }

  @override
  Future<void> assignTask(TaskId taskId, UserId userId) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'assignedToId': userId.value,
                'status': TaskStatus.assigned.name,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to assign task: $e', code: 'TASK_ASSIGN_ERROR');
    }
  }

  @override
  Future<void> unassignTask(TaskId taskId) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'assignedToId': null,
                'status': TaskStatus.available.name,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to unassign task: $e', code: 'TASK_UNASSIGN_ERROR');
    }
  }

  @override
  Future<void> completeTask(TaskId taskId) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'status': TaskStatus.pendingApproval.name,
                'completedAt': FieldValue.serverTimestamp(),
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to complete task: $e', code: 'TASK_COMPLETE_ERROR');
    }
  }

  @override
  Future<void> uncompleteTask(TaskId taskId) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'status': TaskStatus.assigned.name,
                'completedAt': null,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to uncomplete task: $e', code: 'TASK_UNCOMPLETE_ERROR');
    }
  }

  @override
  Future<void> updateTaskStatus(TaskId taskId, TaskStatus status) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'status': status.name,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update task status: $e', code: 'TASK_STATUS_UPDATE_ERROR');
    }
  }

  @override
  Future<Task?> getTask(FamilyId familyId, TaskId taskId) async {
    try {
      final doc = await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .get();

      if (!doc.exists) return null;

      return _mapFirestoreToTask(doc.data()!, doc.id, familyId);
    } catch (e) {
      throw ServerException('Failed to get task: $e', code: 'TASK_FETCH_ERROR');
    }
  }

  @override
  Stream<List<Task>> streamTasks(FamilyId familyId) {
    return _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('tasks')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToTask(doc.data(), doc.id, familyId))
            .toList());
  }

  @override
  Stream<List<Task>> streamAvailableTasks(FamilyId familyId) {
    return _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('tasks')
        .where('status', isEqualTo: TaskStatus.available.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToTask(doc.data(), doc.id, familyId))
            .toList());
  }

  @override
  Stream<List<Task>> streamTasksByAssignee(FamilyId familyId, UserId assigneeId) {
    return _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('tasks')
        .where('assignedToId', isEqualTo: assigneeId.value)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToTask(doc.data(), doc.id, familyId))
            .toList());
  }

  @override
  Future<void> approveTask(TaskId taskId) async {
    // Note: This is a basic implementation. Full approval logic including
    // awarding stars, updating streaks, and sending notifications should be
    // handled by the ApproveTaskUseCase in the domain layer.
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'status': TaskStatus.completed.name,
                'approvedAt': FieldValue.serverTimestamp(),
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to approve task: $e', code: 'TASK_APPROVE_ERROR');
    }
  }

  @override
  Future<void> rejectTask(TaskId taskId, {String? comments}) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'status': TaskStatus.needsRevision.name,
                'rejectionComments': comments,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to reject task: $e', code: 'TASK_REJECT_ERROR');
    }
  }

  @override
  Future<void> claimTask(TaskId taskId, UserId userId) async {
    try {
      final familiesSnapshot = await _firestore.collection('families').get();

      for (final familyDoc in familiesSnapshot.docs) {
        final familyId = FamilyId(familyDoc.id);
        final task = await getTask(familyId, taskId);
        if (task != null) {
          if (task.status != TaskStatus.available) {
            throw ValidationException('Task is not available for claiming', code: 'TASK_NOT_AVAILABLE');
          }
          
          await _firestore
              .collection('families')
              .doc(familyId.value)
              .collection('tasks')
              .doc(taskId.value)
              .update({
                'assignedToId': userId.value,
                'status': TaskStatus.assigned.name,
              });
          return;
        }
      }
      throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to claim task: $e', code: 'TASK_CLAIM_ERROR');
    }
  }

  /// Maps Firestore document data to domain Task entity
  Task _mapFirestoreToTask(Map<String, dynamic> data, String id, FamilyId familyId) {
    // Parse AI rating if present
    AIRating? aiRating;
    if (data['aiRating'] != null && data['aiRating'] is Map) {
      final aiData = data['aiRating'] as Map<String, dynamic>;
      aiRating = AIRating(
        score: (aiData['score'] as num?)?.toDouble() ?? 0.0,
        comment: aiData['comment'] as String? ?? '',
        generatedAt: aiData['generatedAt'] is Timestamp
            ? (aiData['generatedAt'] as Timestamp).toDate()
            : DateTime.tryParse(aiData['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
    }
    
    return Task(
      id: TaskId(id),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.available,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => TaskDifficulty.easy,
      ),
      dueDate: data['dueDate'] is Timestamp
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['dueDate']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 1)),
      assignedToId: data['assignedToId'] != null ? UserId(data['assignedToId'] as String) : null,
      createdById: data['createdById'] != null ? UserId(data['createdById'] as String) : null,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : data['completedAt'] != null
              ? DateTime.tryParse(data['completedAt'].toString())
              : null,
      points: Points(data['points'] as int? ?? 0),
      tags: List<String>.from(data['tags'] ?? []),
      recurringPattern: data['recurringPattern'] as String?,
      lastCompletedAt: data['lastCompletedAt'] is Timestamp
          ? (data['lastCompletedAt'] as Timestamp).toDate()
          : data['lastCompletedAt'] != null
              ? DateTime.tryParse(data['lastCompletedAt'].toString())
              : null,
      familyId: familyId,
      // Photo proof and approval fields
      photoUrl: data['photoUrl'] as String?,
      submittedAt: data['submittedAt'] is Timestamp
          ? (data['submittedAt'] as Timestamp).toDate()
          : data['submittedAt'] != null
              ? DateTime.tryParse(data['submittedAt'].toString())
              : null,
      submittedBy: data['submittedBy'] != null ? UserId(data['submittedBy'] as String) : null,
      aiRating: aiRating,
      approvedBy: data['approvedBy'] != null ? UserId(data['approvedBy'] as String) : null,
      approvedAt: data['approvedAt'] is Timestamp
          ? (data['approvedAt'] as Timestamp).toDate()
          : data['approvedAt'] != null
              ? DateTime.tryParse(data['approvedAt'].toString())
              : null,
      rejectedBy: data['rejectedBy'] != null ? UserId(data['rejectedBy'] as String) : null,
      rejectedAt: data['rejectedAt'] is Timestamp
          ? (data['rejectedAt'] as Timestamp).toDate()
          : data['rejectedAt'] != null
              ? DateTime.tryParse(data['rejectedAt'].toString())
              : null,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  /// Maps domain Task entity to Firestore document data
  Map<String, dynamic> _mapTaskToFirestore(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'status': task.status.name,
      'difficulty': task.difficulty.name,
      'dueDate': task.dueDate,
      'assignedToId': task.assignedToId?.value,
      'createdById': task.createdById?.value,
      'createdAt': task.createdAt,
      'completedAt': task.completedAt,
      'points': task.points.toInt(),
      'tags': task.tags,
      'recurringPattern': task.recurringPattern,
      'lastCompletedAt': task.lastCompletedAt,
      // Photo proof and approval fields
      'photoUrl': task.photoUrl,
      'submittedAt': task.submittedAt,
      'submittedBy': task.submittedBy?.value,
      'aiRating': task.aiRating != null
          ? {
              'score': task.aiRating!.score,
              'comment': task.aiRating!.comment,
              'generatedAt': task.aiRating!.generatedAt,
            }
          : null,
      'approvedBy': task.approvedBy?.value,
      'approvedAt': task.approvedAt,
      'rejectedBy': task.rejectedBy?.value,
      'rejectedAt': task.rejectedAt,
      'rejectionReason': task.rejectionReason,
    };
  }
} 