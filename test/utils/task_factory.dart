import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

/// A minimal [Task] in `family_1`, created by `mum`, for widget tests.
Task testTask({
  required String id,
  required String title,
  required TaskStatus status,
  String? assignedTo,
  bool requiresPhotoProof = false,
}) =>
    Task(
      id: TaskId(id),
      title: title,
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedTo == null ? null : UserId(assignedTo),
      createdById: UserId('mum'),
      createdAt: DateTime(2026, 7, 16),
      points: Points(5),
      tags: const [],
      familyId: FamilyId('family_1'),
      requiresPhotoProof: requiresPhotoProof,
    );
