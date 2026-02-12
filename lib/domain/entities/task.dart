import 'package:equatable/equatable.dart';
import '../value_objects/task_id.dart';
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// AI rating details for task photo proof
class AIRating extends Equatable {
  final double score; // 0-10
  final String comment;
  final DateTime generatedAt;

  const AIRating({
    required this.score,
    required this.comment,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [score, comment, generatedAt];
}

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
  
  // Photo proof and approval fields (Issue #109, #110)
  final String? photoUrl;
  final DateTime? submittedAt;
  final UserId? submittedBy;
  final AIRating? aiRating;
  final UserId? approvedBy;
  final DateTime? approvedAt;
  final UserId? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;

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
    this.photoUrl,
    this.submittedAt,
    this.submittedBy,
    this.aiRating,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
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
    String? photoUrl,
    DateTime? submittedAt,
    UserId? submittedBy,
    AIRating? aiRating,
    UserId? approvedBy,
    DateTime? approvedAt,
    UserId? rejectedBy,
    DateTime? rejectedAt,
    String? rejectionReason,
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
      photoUrl: photoUrl ?? this.photoUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      aiRating: aiRating ?? this.aiRating,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
        photoUrl,
        submittedAt,
        submittedBy,
        aiRating,
        approvedBy,
        approvedAt,
        rejectedBy,
        rejectedAt,
        rejectionReason,
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
  pendingApproval,
  completed,
} 