import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/recurrence.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_recurring_chore_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_creation_notifier.dart';

class _FakeCreateTaskUseCase extends Fake implements CreateTaskUseCase {
  // no-op for the recurring path
}

class _FakeCreateRecurringChoreUseCase extends Fake
    implements CreateRecurringChoreUseCase {
  @override
  Future<Either<Failure, Task>> call({
    required String title,
    String? description,
    required int points,
    required TaskDifficulty difficulty,
    required DateTime dueDate,
    required FamilyId familyId,
    required UserId createdById,
    UserId? assignedToId,
    List<String> tags = const [],
    bool requiresPhotoProof = false,
    required String rrule,
  }) async {
    capturedRrule = rrule;
    return Right(Task(
      id: TaskId('task-1'),
      title: title,
      description: description ?? '',
      status: TaskStatus.available,
      difficulty: difficulty,
      dueDate: dueDate,
      assignedToId: assignedToId,
      createdById: createdById,
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: Points(points),
      tags: tags,
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: familyId,
      requiresPhotoProof: requiresPhotoProof,
      ruleId: 'rule-1',
    ));
  }
}

String? capturedRrule;

void main() {
  test('repeat != never routes to the recurring use case with derived rrule',
      () async {
    capturedRrule = null;
    final container = ProviderContainer(overrides: [
      createTaskUseCaseProvider.overrideWithValue(_FakeCreateTaskUseCase()),
      createRecurringChoreUseCaseProvider
          .overrideWithValue(_FakeCreateRecurringChoreUseCase()),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(taskCreationNotifierProvider.notifier);
    await notifier.createTask(
      title: 'Clean the bathroom',
      description: '',
      difficulty: TaskDifficulty.medium,
      familyId: FamilyId('fam-1'),
      creatorId: UserId('parent-1'),
      dueDate: DateTime(2026, 8, 15), // Saturday
      repeat: RepeatPreset.weekly,
    );

    expect(capturedRrule, 'FREQ=WEEKLY;BYDAY=SA');
    expect(container.read(taskCreationNotifierProvider).isSuccess, isTrue);
  });
}
