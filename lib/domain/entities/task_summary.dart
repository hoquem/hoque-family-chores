import 'package:equatable/equatable.dart';

/// Domain entity representing a summary of tasks for a family
class TaskSummary extends Equatable {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int availableTasks;
  final int needsRevisionTasks;
  final int assignedTasks;
  final int dueToday;
  final int pointsEarned;
  final int completionPercentage;

  const TaskSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.availableTasks,
    required this.needsRevisionTasks,
    required this.assignedTasks,
    required this.dueToday,
    required this.pointsEarned,
    required this.completionPercentage,
  });

  // Computed properties
  int get totalCompleted => completedTasks;
  int get waitingOverall => pendingTasks + needsRevisionTasks;
  int get waitingAssigned => assignedTasks + needsRevisionTasks;
  int get waitingUnassigned => availableTasks;

  /// Creates a copy of this task summary with updated fields
  TaskSummary copyWith({
    int? totalTasks,
    int? completedTasks,
    int? pendingTasks,
    int? availableTasks,
    int? needsRevisionTasks,
    int? assignedTasks,
    int? dueToday,
    int? pointsEarned,
    int? completionPercentage,
  }) {
    return TaskSummary(
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      availableTasks: availableTasks ?? this.availableTasks,
      needsRevisionTasks: needsRevisionTasks ?? this.needsRevisionTasks,
      assignedTasks: assignedTasks ?? this.assignedTasks,
      dueToday: dueToday ?? this.dueToday,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      completionPercentage: completionPercentage ?? this.completionPercentage,
    );
  }

  @override
  List<Object?> get props => [
        totalTasks,
        completedTasks,
        pendingTasks,
        availableTasks,
        needsRevisionTasks,
        assignedTasks,
        dueToday,
        pointsEarned,
        completionPercentage,
      ];
} 