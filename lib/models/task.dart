// lib/models/task.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { available, assigned, pendingApproval, completed }
enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final String? tips;
  final int points;
  final Timestamp createdAt;
  final Timestamp? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String? assigneeId;
  final String? assigneeName;
  final String creatorId;
  final String? creatorName;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final bool isRecurring;
  final String? recurringSchedule; // e.g., 'daily', 'weekly'

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.tips,
    required this.points,
    required this.createdAt,
    this.dueDate,
    required this.priority,
    required this.status,
    this.assigneeId,
    this.assigneeName,
    required this.creatorId,
    this.creatorName,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.isRecurring = false,
    this.recurringSchedule,
  });

  // Factory constructor to create a Task from a Firestore document
  factory Task.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Task(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      tips: data['tips'] as String?,
      points: data['points'] as int,
      createdAt: data['createdAt'] as Timestamp,
      dueDate: data['dueDate'] as Timestamp?,
      priority: TaskPriority.values[data['priority'] as int],
      status: TaskStatus.values[data['status'] as int],
      assigneeId: data['assigneeId'] as String?,
      assigneeName: data['assigneeName'] as String?,
      creatorId: data['creatorId'] as String,
      creatorName: data['creatorName'] as String?,
      beforePhotoUrl: data['beforePhotoUrl'] as String?,
      afterPhotoUrl: data['afterPhotoUrl'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringSchedule: data['recurringSchedule'] as String?,
    );
  }

  // Method to convert a Task instance to a map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tips': tips,
      'points': points,
      'createdAt': createdAt,
      'dueDate': dueDate,
      'priority': priority.index, // Store enums as integers
      'status': status.index,
      'assigneeId': assigneeId,
      'assigneeName': assigneeName,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'beforePhotoUrl': beforePhotoUrl,
      'afterPhotoUrl': afterPhotoUrl,
      'isRecurring': isRecurring,
      'recurringSchedule': recurringSchedule,
    };
  }
}