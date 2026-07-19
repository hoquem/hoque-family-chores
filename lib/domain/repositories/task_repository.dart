import 'dart:async';
import '../entities/task.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../value_objects/task_id.dart';
import '../value_objects/points.dart';

/// Abstract interface for task data operations
abstract class TaskRepository {
  /// Get all tasks for a family
  Future<List<Task>> getTasksForFamily(FamilyId familyId);

  /// Get tasks for a specific user
  Future<List<Task>> getTasksForUser(UserId userId);

  /// Create a new task
  Future<Task> createTask(Task task);

  /// Edit a task's user-editable detail fields with optimistic concurrency.
  ///
  /// Writes only these fields (never status/assignment/photos). Throws
  /// [ConflictException] if the stored version no longer equals [baseVersion]
  /// (another edit landed first) or [NotFoundException] if the task was deleted.
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
  });

  /// Delete a task
  Future<void> deleteTask(FamilyId familyId, TaskId taskId);

  /// Assign a task to a user
  Future<void> assignTask(FamilyId familyId, TaskId taskId, UserId userId);

  /// Unassign a task
  Future<void> unassignTask(FamilyId familyId, TaskId taskId);

  /// Start a task, recording the before photo captured at that moment.
  ///
  /// A targeted update: the whole-document write in [updateTask] would
  /// clobber concurrent changes, and [Task.copyWith] cannot clear fields.
  Future<void> startTask(
    FamilyId familyId,
    TaskId taskId,
    String beforePhotoUrl,
  );

  /// Delete a task's photos and clear their URLs.
  ///
  /// Photos exist to be judged; once a parent has approved, they are pure
  /// cost. Called on approval, and when a started task is handed back.
  ///
  /// Clears the fields with a targeted write: [Task.copyWith] cannot set a
  /// field to null (`x ?? this.x`), so it silently would not clear them.
  Future<void> clearPhotos(FamilyId familyId, TaskId taskId);

  /// Promotes a task's approved "after" photo to the family's Home background.
  ///
  /// Keeps the after-photo file, points `family.backgroundPhotoUrl` at it,
  /// clears the task's photo fields (the family owns the file now), and deletes
  /// the retired previous background plus this task's before-photo. If the task
  /// has no after-photo this behaves like [clearPhotos].
  Future<void> promoteAfterPhotoToBackground(FamilyId familyId, TaskId taskId);

  /// Record the "after" photo for a task.
  ///
  /// Separate from [completeTask] because that does a targeted status write and
  /// takes no photo; and because on rework the after is replaced while the
  /// before persists, so the two photos have different lifetimes.
  Future<void> setAfterPhoto(
    FamilyId familyId,
    TaskId taskId,
    String photoUrl,
  );

  /// Complete a task
  Future<void> completeTask(FamilyId familyId, TaskId taskId);

  /// Uncomplete a task
  Future<void> uncompleteTask(FamilyId familyId, TaskId taskId);

  /// Update task status
  Future<void> updateTaskStatus(FamilyId familyId, TaskId taskId, TaskStatus status);

  /// Get a specific task
  Future<Task?> getTask(FamilyId familyId, TaskId taskId);

  /// Stream all tasks for a family
  Stream<List<Task>> streamTasks(FamilyId familyId);

  /// Stream available tasks for a family
  Stream<List<Task>> streamAvailableTasks(FamilyId familyId);

  /// Stream tasks assigned to a specific user
  Stream<List<Task>> streamTasksByAssignee(FamilyId familyId, UserId assigneeId);

  /// Approve a task
  Future<void> approveTask(FamilyId familyId, TaskId taskId);

  /// Reject a task
  Future<void> rejectTask(FamilyId familyId, TaskId taskId, {String? comments});

  /// Claim a task
  Future<void> claimTask(FamilyId familyId, TaskId taskId, UserId userId);
} 