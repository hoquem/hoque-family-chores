import 'package:equatable/equatable.dart';
import '../value_objects/task_id.dart';
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// Domain entity representing a task
class Task extends Equatable {
  final TaskId id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final DateTime dueDate;
  final UserId? assignedToId;
  final UserId? createdById;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Points points;
  final List<String> tags;
  final String? recurringPattern;
  final DateTime? lastCompletedAt;
  final FamilyId familyId;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.difficulty,
    required this.dueDate,
    this.assignedToId,
    this.createdById,
    required this.createdAt,
    this.completedAt,
    required this.points,
    required this.tags,
    this.recurringPattern,
    this.lastCompletedAt,
    required this.familyId,
  });

  /// Creates a copy of this task with updated fields
  Task copyWith({
    TaskId? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    DateTime? dueDate,
    UserId? assignedToId,
    UserId? createdById,
    DateTime? createdAt,
    DateTime? completedAt,
    Points? points,
    List<String>? tags,
    String? recurringPattern,
    DateTime? lastCompletedAt,
    FamilyId? familyId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      assignedToId: assignedToId ?? this.assignedToId,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      familyId: familyId ?? this.familyId,
    );
  }

  /// Check if task is available for claiming
  bool get isAvailable => status == TaskStatus.available;

  /// Check if task is assigned to someone
  bool get isAssigned => status == TaskStatus.assigned;

  /// Check if task is completed
  bool get isCompleted => status == TaskStatus.completed;

  /// Check if task is pending approval
  bool get isPendingApproval => status == TaskStatus.pendingApproval;

  /// Check if task needs revision
  bool get needsRevision => status == TaskStatus.needsRevision;

  /// Check if task is overdue
  bool get isOverdue => dueDate.isBefore(DateTime.now()) && !isCompleted;

  /// Check if task is due today
  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDateOnly.isAtSameMomentAs(today);
  }

  /// Check if task is due tomorrow
  bool get isDueTomorrow {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dueDateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return dueDateOnly.isAtSameMomentAs(tomorrow);
  }

  /// Check if task is assigned to a specific user
  bool isAssignedTo(UserId userId) {
    return assignedToId == userId;
  }

  /// Check if task was created by a specific user
  bool isCreatedBy(UserId userId) {
    return createdById == userId;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        difficulty,
        dueDate,
        assignedToId,
        createdById,
        createdAt,
        completedAt,
        points,
        tags,
        recurringPattern,
        lastCompletedAt,
        familyId,
      ];
}

/// Task status in the workflow
enum TaskStatus {
  available, // For anyone to claim
  assigned, // Claimed by a user
  pendingApproval, // Submitted for review
  needsRevision, // Rejected by a parent, needs changes
  completed, // Approved and finished
}

/// Task difficulty levels
enum TaskDifficulty {
  easy,
  medium,
  hard,
  challenging;

  /// Get display name for the difficulty
  String get displayName {
    switch (this) {
      case TaskDifficulty.easy:
        return 'Easy';
      case TaskDifficulty.medium:
        return 'Medium';
      case TaskDifficulty.hard:
        return 'Hard';
      case TaskDifficulty.challenging:
        return 'Challenging';
    }
  }

  /// Get points multiplier for the difficulty
  double get pointsMultiplier {
    switch (this) {
      case TaskDifficulty.easy:
        return 1.0;
      case TaskDifficulty.medium:
        return 1.5;
      case TaskDifficulty.hard:
        return 2.0;
      case TaskDifficulty.challenging:
        return 3.0;
    }
  }
}

/// Task filter types for UI
enum TaskFilterType {
  all,
  myTasks,
  available,
  completed,
} 