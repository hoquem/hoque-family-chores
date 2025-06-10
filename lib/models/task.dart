// lib/models/task.dart
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/enum_helpers.dart'; // <--- NEW: Import enum_helpers

class Task {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final int points;
  final TaskStatus status;
  final String familyId;
  // Add other fields as needed (e.g., creatorId, dueAt, completedAt, revisionComments)

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.assigneeId,
    required this.points,
    this.status = TaskStatus.available,
    required this.familyId,
  });

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    // Use enumFromString for TaskStatus
    final status = enumFromString(
      data['status'] as String?,
      TaskStatus.values,
      defaultValue: TaskStatus.available, // Provide a safe default
    );

    return Task(
      id: id,
      title: data['title'] as String? ?? 'No Title',
      description: data['description'] as String? ?? '',
      assigneeId: data['assigneeId'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      status: status, // Use the parsed status
      familyId: data['familyId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'points': points,
      'status': status.name, // Use .name for enum
      'familyId': familyId,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? assigneeId,
    int? points,
    TaskStatus? status,
    String? familyId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      points: points ?? this.points,
      status: status ?? this.status,
      familyId: familyId ?? this.familyId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          assigneeId == other.assigneeId &&
          points == other.points &&
          status == other.status &&
          familyId == other.familyId;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      assigneeId.hashCode ^
      points.hashCode ^
      status.hashCode ^
      familyId.hashCode;
}