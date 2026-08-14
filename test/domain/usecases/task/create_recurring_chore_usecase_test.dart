import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/recurring_rule.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/create_recurring_chore_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepository repo;
  late CreateRecurringChoreUseCase useCase;

  setUpAll(() {
    registerFallbackValue(Task(
      id: TaskId('fallback'),
      title: 'fallback',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 15),
      createdById: UserId('fallback'),
      createdAt: DateTime(2026, 8, 14),
      points: Points(1),
      tags: const [],
      familyId: FamilyId('fallback'),
    ));
    registerFallbackValue(RecurringRule(
      id: 'fallback',
      familyId: FamilyId('fallback'),
      rrule: 'FREQ=DAILY',
      title: 'fallback',
      description: '',
      difficulty: TaskDifficulty.easy,
      points: Points(1),
      tags: const [],
      requiresPhotoProof: false,
      createdBy: UserId('fallback'),
      nextDueAt: DateTime(2026, 8, 15),
    ));
  });

  setUp(() {
    repo = _MockTaskRepository();
    useCase = CreateRecurringChoreUseCase(repo);
  });

  test('creates the recurring chore with a valid template', () async {
    final created = Task(
      id: TaskId('task-1'),
      title: 'Clean the bathroom',
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      assignedToId: null,
      createdById: UserId('parent-1'),
      createdAt: DateTime(2026, 8, 14),
      completedAt: null,
      points: Points(25),
      tags: const [],
      recurringPattern: null,
      lastCompletedAt: null,
      familyId: FamilyId('fam-1'),
      requiresPhotoProof: false,
      ruleId: 'rule-1',
    );
    when(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')))
        .thenAnswer((_) async => created);

    final result = await useCase.call(
      title: 'Clean the bathroom',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      familyId: FamilyId('fam-1'),
      createdById: UserId('parent-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
    );

    expect(result, isA<Right<Failure, Task>>());
    expect(result.getOrElse(() => throw StateError('unreachable')).ruleId, 'rule-1');

    final captured = verify(() => repo.createRecurringChore(
        firstTask: captureAny(named: 'firstTask'), rule: captureAny(named: 'rule')))
        .captured;
    final rule = captured[1] as RecurringRule;
    expect(rule.rrule, 'FREQ=WEEKLY;BYDAY=SA');
    expect(rule.nextDueAt, DateTime(2026, 8, 15));
    expect(rule.lastTaskId, isNull); // repository assigns the real id
    final firstTask = captured[0] as Task;
    expect(firstTask.status, TaskStatus.available);
    expect(firstTask.ruleId, isNull);
  });

  test('passes through an invalid title as a ValidationFailure', () async {
    final result = await useCase.call(
      title: '   ',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2026, 8, 15),
      familyId: FamilyId('fam-1'),
      createdById: UserId('parent-1'),
      rrule: 'FREQ=DAILY',
    );

    expect(result, isA<Left<Failure, Task>>());
    expect(result.swap().getOrElse(() => throw StateError('unreachable')),
        isA<ValidationFailure>());
    verifyNever(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')));
  });

  test('past due date is rejected before touching the repository', () async {
    final result = await useCase.call(
      title: 'Clean the bathroom',
      points: 25,
      difficulty: TaskDifficulty.medium,
      dueDate: DateTime(2020, 1, 1),
      familyId: FamilyId('fam-1'),
      createdById: UserId('parent-1'),
      rrule: 'FREQ=WEEKLY;BYDAY=SA',
    );

    expect(result, isA<Left<Failure, Task>>());
    verifyNever(() => repo.createRecurringChore(
        firstTask: any(named: 'firstTask'), rule: any(named: 'rule')));
  });
}
