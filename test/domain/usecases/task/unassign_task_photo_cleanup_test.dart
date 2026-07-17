// Handing a task back must take its before photo with it.
//
// A task returned to the pool carries nothing from its previous holder. If the
// before photo survived, the next child to claim it would start against a
// stranger's mess — and their "after" would be judged against a room they
// never saw.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/unassign_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
  });

  late _MockTaskRepository tasks;
  late UnassignTaskUseCase useCase;

  setUp(() {
    tasks = _MockTaskRepository();
    useCase = UnassignTaskUseCase(tasks);
    when(() => tasks.unassignTask(any(), any())).thenAnswer((_) async {});
    when(() => tasks.clearPhotos(any(), any())).thenAnswer((_) async {});
  });

  test('handing a task back deletes its photos', () async {
    await useCase(taskId: _taskId, familyId: _familyId);
    verify(() => tasks.clearPhotos(_familyId, _taskId)).called(1);
  });

  test('photos are cleared BEFORE the task returns to the pool', () async {
    // Order matters: unassign first and another child could claim the task in
    // the gap, inheriting the previous holder's before photo.
    await useCase(taskId: _taskId, familyId: _familyId);
    verifyInOrder([
      () => tasks.clearPhotos(_familyId, _taskId),
      () => tasks.unassignTask(_familyId, _taskId),
    ]);
  });

  test('a failed cleanup DOES fail the unassign', () async {
    // The opposite call to approval's. There, the task was already approved and
    // the photos were spent, so a failed delete only leaked cost. Here the
    // photo is still live evidence: returning the task while it survives hands
    // the next child a stranger's mess. Better to fail and let them retry.
    when(() => tasks.clearPhotos(any(), any()))
        .thenThrow(Exception('storage unreachable'));

    final result = await useCase(taskId: _taskId, familyId: _familyId);

    expect(result.isLeft(), isTrue);
    verifyNever(() => tasks.unassignTask(any(), any()));
  });

  // No test for the use case's empty-task-id guard: TaskId('') throws at
  // construction (task_id.dart:12), so that branch is unreachable and cannot
  // be exercised. Left in place rather than removed — it is pre-existing and
  // harmless, and deleting it is not this feature's business.
}
