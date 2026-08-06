// Sending a chore back for another go.
//
// This is the only path that produces TaskStatus.needsRevision, and it had
// zero coverage. That mattered more than the number: the Tasks tile and the
// detail screen both changed behaviour for needsRevision recently, and if this
// path were broken the way notification mark-as-read was, that state would be
// unreachable in production with nothing failing to say so.
//
// Who may reject is not decided here — taskActionsFor hides the button from
// the doer, and the Cloud Function is the authoritative guard. What this owns
// is turning a rejection into a repository call, and turning failures into
// Failures instead of exceptions.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/reject_task_usecase.dart';
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
  late RejectTaskUseCase reject;

  setUp(() {
    tasks = _MockTaskRepository();
    reject = RejectTaskUseCase(tasks);
    when(() => tasks.rejectTask(any(), any(),
        comments: any(named: 'comments'))).thenAnswer((_) async {});
  });

  test('sending a chore back reaches the repository', () async {
    final result = await reject(taskId: _taskId, familyId: _familyId);

    expect(result.isRight(), isTrue);
    verify(() => tasks.rejectTask(_familyId, _taskId, comments: null))
        .called(1);
  });

  // The child is about to be told to do it again; the reason is the whole
  // difference between that being fair and being arbitrary.
  test('the reason travels with it', () async {
    final result = await reject(
      taskId: _taskId,
      familyId: _familyId,
      comments: 'The corners are still dusty',
    );

    expect(result.isRight(), isTrue);
    verify(() => tasks.rejectTask(_familyId, _taskId,
        comments: 'The corners are still dusty')).called(1);
  });

  test('an empty task id is refused before it reaches the repository',
      () async {
    final result = await reject(taskId: TaskId('   '), familyId: _familyId);

    expect(result.fold((f) => f, (_) => null), isA<ValidationFailure>());
    verifyNever(() => tasks.rejectTask(any(), any(),
        comments: any(named: 'comments')));
  });

  test('a missing chore is a failure, not a crash', () async {
    when(() => tasks.rejectTask(any(), any(),
            comments: any(named: 'comments')))
        .thenThrow(const NotFoundException('Task not found',
            code: 'TASK_NOT_FOUND'));

    final result = await reject(taskId: _taskId, familyId: _familyId);

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<ServerFailure>());
    expect(failure!.message, 'Task not found');
  });

  test('an unexpected error is still a failure, never a crash', () async {
    when(() => tasks.rejectTask(any(), any(),
        comments: any(named: 'comments'))).thenThrow(StateError('boom'));

    final result = await reject(taskId: _taskId, familyId: _familyId);

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });
}
