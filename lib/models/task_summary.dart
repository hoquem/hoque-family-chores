// lib/models/task_summary.dart

class TaskSummary {
  final int totalCompleted;
  final int dueToday;
  final int waitingOverall;
  final int waitingAssigned;
  final int waitingUnassigned;

  TaskSummary({
    required this.totalCompleted,
    required this.dueToday,
    required this.waitingOverall,
    required this.waitingAssigned,
    required this.waitingUnassigned,
  });
}