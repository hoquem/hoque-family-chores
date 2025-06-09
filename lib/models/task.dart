// lib/models/task.dart
import 'package:hoque_family_chores/models/enums.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final int points;
  final TaskStatus status;
  final String? assigneeName;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.status,
    this.assigneeName,
    this.dueDate,
  });

  factory Task.fromMap(Map<String, dynamic> data) {
    return Task(
      id: data['id'] ?? '',
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? '',
      points: data['pointValue'] ?? data['points'] ?? 0,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      assigneeName: data['assigneeName'] ?? data['assigneeId'],
      dueDate: data['dueDate'] != null ? DateTime.tryParse(data['dueDate']) : null,
    );
  }
}