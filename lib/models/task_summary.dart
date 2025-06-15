// lib/models/task_summary.dart
import 'package:hoque_family_chores/models/base_model.dart';

// --- TaskSummary-related Enums (kept in this file for encapsulation) ---
enum TaskSummaryState { loading, loaded, error }

enum AvailableTasksState { loading, loaded, error, claiming }

class TaskSummary extends BaseModel {
  @override
  final String id;
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int availableTasks;
  final int needsRevisionTasks;
  final int assignedTasks;
  final int dueToday;

  TaskSummary({
    this.id = 'summary',
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.pendingTasks = 0,
    this.availableTasks = 0,
    this.needsRevisionTasks = 0,
    this.assignedTasks = 0,
    this.dueToday = 0,
  });

  // Computed properties
  int get totalCompleted => completedTasks;
  int get waitingOverall => pendingTasks + needsRevisionTasks;
  int get waitingAssigned => assignedTasks + needsRevisionTasks;
  int get waitingUnassigned => availableTasks;

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      id: json['id'] ?? 'summary',
      totalTasks: json['totalTasks'] as int? ?? 0,
      completedTasks: json['completedTasks'] as int? ?? 0,
      pendingTasks: json['pendingTasks'] as int? ?? 0,
      availableTasks: json['availableTasks'] as int? ?? 0,
      needsRevisionTasks: json['needsRevisionTasks'] as int? ?? 0,
      assignedTasks: json['assignedTasks'] as int? ?? 0,
      dueToday: json['dueToday'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
      'availableTasks': availableTasks,
      'needsRevisionTasks': needsRevisionTasks,
      'assignedTasks': assignedTasks,
      'dueToday': dueToday,
    };
  }

  @override
  TaskSummary copyWith({
    String? id,
    int? totalTasks,
    int? completedTasks,
    int? pendingTasks,
    int? availableTasks,
    int? needsRevisionTasks,
    int? assignedTasks,
    int? dueToday,
  }) {
    return TaskSummary(
      id: id ?? this.id,
      totalTasks: totalTasks ?? this.totalTasks,
      completedTasks: completedTasks ?? this.completedTasks,
      pendingTasks: pendingTasks ?? this.pendingTasks,
      availableTasks: availableTasks ?? this.availableTasks,
      needsRevisionTasks: needsRevisionTasks ?? this.needsRevisionTasks,
      assignedTasks: assignedTasks ?? this.assignedTasks,
      dueToday: dueToday ?? this.dueToday,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskSummary &&
        other.id == id &&
        other.totalTasks == totalTasks &&
        other.completedTasks == completedTasks &&
        other.pendingTasks == pendingTasks &&
        other.availableTasks == availableTasks &&
        other.needsRevisionTasks == needsRevisionTasks &&
        other.assignedTasks == assignedTasks &&
        other.dueToday == dueToday;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      totalTasks,
      completedTasks,
      pendingTasks,
      availableTasks,
      needsRevisionTasks,
      assignedTasks,
      dueToday,
    );
  }
}
