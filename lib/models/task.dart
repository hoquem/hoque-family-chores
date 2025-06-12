// lib/models/task.dart
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final int points;
  final TaskStatus status;
  final String familyId;
  final String creatorId;
  final String? assigneeId;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.status,
    required this.familyId,
    required this.creatorId,
    this.assigneeId,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    logger.d("Task.fromFirestore: Parsing task data: $data");

    DateTime? dueDate;
    if (data['dueDate'] != null) {
      try {
        if (data['dueDate'] is Timestamp) {
          dueDate = (data['dueDate'] as Timestamp).toDate();
        } else if (data['dueDate'] is String) {
          dueDate = DateTime.parse(data['dueDate']);
        }
      } catch (e, s) {
        logger.e(
          "Task.fromFirestore: Error parsing dueDate: $e",
          error: e,
          stackTrace: s,
        );
      }
    }

    return Task(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TaskStatus.available,
      ),
      familyId: data['familyId'] ?? '',
      creatorId: data['creatorId'] ?? '',
      assigneeId: data['assigneeId'],
      dueDate: dueDate,
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      updatedAt:
          data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'points': points,
      'status': status.name,
      'familyId': familyId,
      'creatorId': creatorId,
      'assigneeId': assigneeId,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    TaskStatus? status,
    String? familyId,
    String? creatorId,
    String? assigneeId,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      status: status ?? this.status,
      familyId: familyId ?? this.familyId,
      creatorId: creatorId ?? this.creatorId,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.points == points &&
        other.status == status &&
        other.familyId == familyId &&
        other.creatorId == creatorId &&
        other.assigneeId == assigneeId &&
        other.dueDate == dueDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      points,
      status,
      familyId,
      creatorId,
      assigneeId,
      dueDate,
      createdAt,
      updatedAt,
    );
  }
}
