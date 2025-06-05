// lib/models/task.dart

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final String? assigneeId; // Corresponds to FamilyMember.id
  final DateTime? dueDate;
  final TaskPriority priority;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.assigneeId,
    this.dueDate,
    this.priority = TaskPriority.medium,
  });
}