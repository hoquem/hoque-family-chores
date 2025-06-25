// lib/models/task.dart
// import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/family_member.dart';

class Task {
  @override
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskDifficulty difficulty;
  final DateTime dueDate;
  final FamilyMember? assignedTo;
  final FamilyMember? createdBy;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int points;
  final List<String> tags;
  final String? recurringPattern;
  final DateTime? lastCompletedAt;
  final String familyId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.difficulty,
    required this.dueDate,
    this.assignedTo,
    this.createdBy,
    required this.createdAt,
    this.completedAt,
    required this.points,
    required this.tags,
    this.recurringPattern,
    this.lastCompletedAt,
    required this.familyId,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    DateTime? dueDate,
    FamilyMember? assignedTo,
    FamilyMember? createdBy,
    DateTime? createdAt,
    DateTime? completedAt,
    int? points,
    List<String>? tags,
    String? recurringPattern,
    DateTime? lastCompletedAt,
    String? familyId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      familyId: familyId ?? this.familyId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.toString(),
      'difficulty': difficulty.toString(),
      'dueDate': dueDate.toIso8601String(),
      'assignedTo': assignedTo?.toJson(),
      'createdBy': createdBy?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'points': points,
      'tags': tags,
      'recurringPattern': recurringPattern,
      'lastCompletedAt': lastCompletedAt?.toIso8601String(),
      'familyId': familyId,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TaskStatus.available,
      ),
      difficulty: TaskDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => TaskDifficulty.easy,
      ),
      dueDate: DateTime.parse(json['dueDate'] as String),
      assignedTo:
          json['assignedTo'] != null
              ? FamilyMember.fromJson(
                json['assignedTo'] as Map<String, dynamic>,
              )
              : null,
      createdBy:
          json['createdBy'] != null
              ? FamilyMember.fromJson(json['createdBy'] as Map<String, dynamic>)
              : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      points: json['points'] as int,
      tags: List<String>.from(json['tags'] as List),
      recurringPattern: json['recurringPattern'] as String?,
      lastCompletedAt:
          json['lastCompletedAt'] != null
              ? DateTime.parse(json['lastCompletedAt'] as String)
              : null,
      familyId: json['familyId'] as String,
    );
  }
}

// --- Task-related Enums (kept in this file for encapsulation) ---
enum TaskStatus {
  available, // For anyone to claim
  assigned, // Claimed by a user
  pendingApproval, // Submitted for review
  needsRevision, // Rejected by a parent, needs changes
  completed, // Approved and finished
}

enum TaskFilterType { all, myTasks, available, completed }

enum TaskDifficulty { easy, medium, hard, challenging }
