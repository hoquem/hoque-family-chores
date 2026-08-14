import 'package:equatable/equatable.dart';
import '../entities/task.dart' show TaskDifficulty;
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// A recurring-chore rule: the template a chore is spawned from, on the
/// schedule its RRULE describes. Stored at families/{familyId}/taskRules.
/// The client only ever *creates* and *deletes* these — reading them back is
/// the engine's job.
class RecurringRule extends Equatable {
  final String id;
  final FamilyId familyId;
  final String rrule;
  final String title;
  final String description;
  final TaskDifficulty difficulty;
  final Points points;
  final List<String> tags;
  final bool requiresPhotoProof;

  /// Null = unassigned ("up for grabs"); otherwise the fixed child.
  final UserId? assignedToId;

  final UserId createdBy;

  /// When the next occurrence is due. At creation this equals the first
  /// task's due date; the engine advances it from there.
  final DateTime nextDueAt;

  /// Gating: the engine waits for the occurrence this points at to resolve
  /// before spawning the next. Set by the creation batch write and the engine.
  final String? lastTaskId;

  const RecurringRule({
    required this.id,
    required this.familyId,
    required this.rrule,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.tags,
    required this.requiresPhotoProof,
    this.assignedToId,
    required this.createdBy,
    required this.nextDueAt,
    this.lastTaskId,
  });

  RecurringRule copyWith({
    String? id,
    FamilyId? familyId,
    String? rrule,
    String? title,
    String? description,
    TaskDifficulty? difficulty,
    Points? points,
    List<String>? tags,
    bool? requiresPhotoProof,
    UserId? assignedToId,
    UserId? createdBy,
    DateTime? nextDueAt,
    String? lastTaskId,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      rrule: rrule ?? this.rrule,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      points: points ?? this.points,
      tags: tags ?? this.tags,
      requiresPhotoProof: requiresPhotoProof ?? this.requiresPhotoProof,
      assignedToId: assignedToId ?? this.assignedToId,
      createdBy: createdBy ?? this.createdBy,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      lastTaskId: lastTaskId ?? this.lastTaskId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        familyId,
        rrule,
        title,
        description,
        difficulty,
        points,
        tags,
        requiresPhotoProof,
        assignedToId,
        createdBy,
        nextDueAt,
        lastTaskId,
      ];
}
