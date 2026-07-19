import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/entities/task.dart';
import '../../domain/value_objects/task_id.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';
import '../services/economy_functions.dart';
import '../services/photo_storage_service.dart';

/// Firebase implementation of TaskRepository
class FirebaseTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  final PhotoStorageService _photos;
  final EconomyFunctions _economy;

  FirebaseTaskRepository({
    FirebaseFirestore? firestore,
    PhotoStorageService? photoStorage,
    EconomyFunctions? economy,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _photos = photoStorage ?? PhotoStorageService(),
        _economy = economy ?? EconomyFunctions();

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
  Future<void> editTaskDetails({
    required FamilyId familyId,
    required TaskId taskId,
    required int baseVersion,
    required String title,
    required String description,
    required TaskDifficulty difficulty,
    required Points points,
    required DateTime dueDate,
    required bool requiresPhotoProof,
  }) async {
    final taskRef = _firestore
        .collection('families')
        .doc(familyId.value)
        .collection('tasks')
        .doc(taskId.value);

    try {
      // Optimistic concurrency: the whole read-compare-write runs inside the
      // transaction, so Firestore serializes concurrent editors. Only the
      // editable detail fields are written — a child's claim/completion (status,
      // assignedToId, photos) is never touched. `version` is bumped only here,
      // so a claim in another tab does not raise a false conflict.
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(taskRef);
        if (!snapshot.exists) {
          throw NotFoundException(
            'This task was removed by someone else.',
            code: 'TASK_DELETED',
          );
        }
        final currentVersion =
            (snapshot.data()?['version'] as num?)?.toInt() ?? 0;
        if (currentVersion != baseVersion) {
          throw ConflictException(
            'This task was changed by someone else.',
            code: 'TASK_CONFLICT',
          );
        }
        transaction.update(taskRef, {
          'title': title,
          'description': description,
          'difficulty': difficulty.name,
          'points': points.toInt(),
          'dueDate': dueDate,
          'requiresPhotoProof': requiresPhotoProof,
          'version': currentVersion + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on DataException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to edit task: $e', code: 'TASK_EDIT_ERROR');
    }
  }

  @override
  Future<void> deleteTask(FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .delete();
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete task: $e', code: 'TASK_DELETE_ERROR');
    }
  }

  @override
  Future<void> assignTask(FamilyId familyId, TaskId taskId, UserId userId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
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
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to assign task: $e', code: 'TASK_ASSIGN_ERROR');
    }
  }

  @override
  Future<void> unassignTask(FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'assignedToId': null,
            'status': TaskStatus.available.name,
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to unassign task: $e', code: 'TASK_UNASSIGN_ERROR');
    }
  }

  @override
  Future<void> startTask(
    FamilyId familyId,
    TaskId taskId,
    String beforePhotoUrl,
  ) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'status': TaskStatus.inProgress.name,
            'beforePhotoUrl': beforePhotoUrl,
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to start task: $e', code: 'TASK_START_ERROR');
    }
  }

  @override
  Future<void> clearPhotos(FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      // Blobs first: if the URLs were cleared first and a delete then failed,
      // the blob would be unreachable and impossible to clean up later.
      for (final url in [task.beforePhotoUrl, task.photoUrl]) {
        if (url == null) continue;
        final result = await _photos.delete(url);
        result.fold(
          (failure) => throw ServerException(
            'Failed to delete task photo: ${failure.message}',
            code: 'PHOTO_DELETE_ERROR',
          ),
          (_) {},
        );
      }

      // A targeted null write. Task.copyWith cannot clear a field — every line
      // is `x ?? this.x` — so it would silently leave the URLs in place.
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'beforePhotoUrl': null,
            'photoUrl': null,
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to clear task photos: $e',
          code: 'PHOTO_CLEAR_ERROR');
    }
  }

  @override
  Future<void> promoteAfterPhotoToBackground(
      FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }
      final afterUrl = task.photoUrl;
      if (afterUrl == null) {
        // Nothing to promote — behave like clearPhotos.
        await clearPhotos(familyId, taskId);
        return;
      }

      final familyRef =
          _firestore.collection('families').doc(familyId.value);
      final oldBackground =
          (await familyRef.get()).data()?['backgroundPhotoUrl'] as String?;

      // Point the family at the kept after-photo. This is the important write;
      // it happens before any delete so the background is set even if cleanup
      // later fails.
      await familyRef.update({
        'backgroundPhotoUrl': afterUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // The task no longer owns the after-photo (the family's background uses
      // it now); clear its photo fields so nothing later deletes that file.
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({'beforePhotoUrl': null, 'photoUrl': null});

      // Best-effort: retire the before-photo and the previous background blob.
      for (final url in [task.beforePhotoUrl, oldBackground]) {
        if (url == null || url == afterUrl) continue;
        final result = await _photos.delete(url);
        result.fold(
          (failure) => throw ServerException(
            'Failed to delete retired photo: ${failure.message}',
            code: 'PHOTO_DELETE_ERROR',
          ),
          (_) {},
        );
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to promote task photo: $e',
          code: 'PHOTO_PROMOTE_ERROR');
    }
  }

  @override
  Future<void> setAfterPhoto(
    FamilyId familyId,
    TaskId taskId,
    String photoUrl,
  ) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      // Targeted write. The whole-document toFirestore in updateTask would
      // clobber concurrent changes, and on rework this simply overwrites the
      // previous attempt's photo, which is correct: a parent judges the latest.
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({'photoUrl': photoUrl});
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to store task photo: $e',
          code: 'PHOTO_STORE_ERROR');
    }
  }

  @override
  Future<void> completeTask(FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'status': TaskStatus.pendingApproval.name,
            'completedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to complete task: $e', code: 'TASK_COMPLETE_ERROR');
    }
  }

  @override
  Future<void> uncompleteTask(FamilyId familyId, TaskId taskId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'status': TaskStatus.assigned.name,
            'completedAt': null,
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to uncomplete task: $e', code: 'TASK_UNCOMPLETE_ERROR');
    }
  }

  @override
  Future<void> updateTaskStatus(FamilyId familyId, TaskId taskId, TaskStatus status) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'status': status.name,
          });
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
  Future<void> approveTask(FamilyId familyId, TaskId taskId) =>
      // Approving and awarding stars now happen server-side (Cloud Function):
      // the client can't write `points`, and the Function runs the same
      // in-transaction status re-read guard so nothing pays twice. Non-parents
      // can't approve their own work; parents may (edit-mode override).
      _economy.approveTask(familyId, taskId);

  @override
  Future<void> rejectTask(FamilyId familyId, TaskId taskId, {String? comments}) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('tasks')
          .doc(taskId.value)
          .update({
            'status': TaskStatus.needsRevision.name,
            'rejectionReason': comments,
          });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to reject task: $e', code: 'TASK_REJECT_ERROR');
    }
  }

  @override
  Future<void> claimTask(FamilyId familyId, TaskId taskId, UserId userId) async {
    try {
      final task = await getTask(familyId, taskId);
      if (task == null) {
        throw NotFoundException('Task not found', code: 'TASK_NOT_FOUND');
      }

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
      requiresPhotoProof: data['requiresPhotoProof'] as bool? ?? false,
      photoUrl: data['photoUrl'] as String?,
      beforePhotoUrl: data['beforePhotoUrl'] as String?,
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
      version: (data['version'] as num?)?.toInt() ?? 0,
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
      'requiresPhotoProof': task.requiresPhotoProof,
      'photoUrl': task.photoUrl,
      'beforePhotoUrl': task.beforePhotoUrl,
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
      'version': task.version,
    };
  }
} 