import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/utils/json_parser.dart';
import 'package:hoque_family_chores/utils/logger.dart';

// --- Task-related Enums (co-located for encapsulation) ---
enum TaskStatus {
  available, // For anyone to claim
  assigned, // Claimed by a user
  pendingApproval, // Submitted for review
  needsRevision, // Rejected by a parent, needs changes
  completed, // Approved and finished
}

enum TaskFilterType { all, myTasks, available, completed }

enum TaskDifficulty { easy, medium, hard, challenging }

class Task {
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

  // --- Convenience getter for backward compatibility ---
  String? get assigneeId => assignedTo?.id;

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
      'status': status.name,
      'difficulty': difficulty.name,
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
    final logger = AppLogger();
    
    try {
      return Task(
        id: JsonParser.parseRequiredString(json, 'id'),
        title: JsonParser.parseRequiredString(json, 'title'),
        description: JsonParser.parseRequiredString(json, 'description'),
        status: JsonParser.parseRequiredEnum(json, 'status', TaskStatus.values, TaskStatus.available),
        difficulty: JsonParser.parseRequiredEnum(json, 'difficulty', TaskDifficulty.values, TaskDifficulty.easy),
        dueDate: JsonParser.parseDateTime(json, 'dueDate', defaultValue: DateTime.now().add(const Duration(days: 1))) ?? DateTime.now().add(const Duration(days: 1)),
        assignedTo: JsonParser.parseObject(json, 'assignedTo')?.let((obj) => FamilyMember.fromJson(obj)),
        createdBy: JsonParser.parseObject(json, 'createdBy')?.let((obj) => FamilyMember.fromJson(obj)),
        createdAt: JsonParser.parseRequiredDateTime(json, 'createdAt'),
        completedAt: JsonParser.parseDateTime(json, 'completedAt'),
        points: JsonParser.parseRequiredInt(json, 'points'),
        tags: JsonParser.parseRequiredList(json, 'tags', (item) => item.toString()),
        recurringPattern: JsonParser.parseString(json, 'recurringPattern'),
        lastCompletedAt: JsonParser.parseDateTime(json, 'lastCompletedAt'),
        familyId: JsonParser.parseRequiredString(json, 'familyId'),
      );
    } catch (e) {
      logger.e('Failed to parse Task from JSON: $e');
      logger.d('JSON data: $json');
      
      // Return a minimal valid task with defaults
      return Task(
        id: JsonParser.parseString(json, 'id') ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        title: JsonParser.parseString(json, 'title') ?? 'Unknown Task',
        description: JsonParser.parseString(json, 'description') ?? 'Task description not available',
        status: JsonParser.parseEnum(json, 'status', TaskStatus.values, TaskStatus.available) ?? TaskStatus.available,
        difficulty: JsonParser.parseEnum(json, 'difficulty', TaskDifficulty.values, TaskDifficulty.easy) ?? TaskDifficulty.easy,
        dueDate: JsonParser.parseDateTime(json, 'dueDate') ?? DateTime.now().add(const Duration(days: 1)),
        assignedTo: null,
        createdBy: null,
        createdAt: JsonParser.parseDateTime(json, 'createdAt') ?? DateTime.now(),
        completedAt: JsonParser.parseDateTime(json, 'completedAt'),
        points: JsonParser.parseInt(json, 'points', defaultValue: 10) ?? 10,
        tags: JsonParser.parseList(json, 'tags', (item) => item.toString(), defaultValue: []) ?? [],
        recurringPattern: JsonParser.parseString(json, 'recurringPattern'),
        lastCompletedAt: JsonParser.parseDateTime(json, 'lastCompletedAt'),
        familyId: JsonParser.parseString(json, 'familyId') ?? 'unknown-family',
      );
    }
  }

  /// Factory method for creating tasks from Firestore documents
  factory Task.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return Task.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
  }
} 