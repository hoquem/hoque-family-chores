// You cannot judge your own chore.
//
// This is the one rule holding the star economy honest. Anyone in the family
// creates tasks and anyone approves them — deliberately, because a family is
// peers, not a hierarchy. But without this guard a child could create "Tidy
// room, 100⭐", assign it to themselves, tap Done, tap Approve, and mint stars
// from nothing. With Rewards those stars buy a real family meal, so this stops
// being a nuisance and starts being a working exploit.
//
// Until now ApproveTaskUseCase validated nothing at all: the approver check was
// a TODO, and only the UI hid the buttons from non-parents. A UI is not a
// security boundary.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/repositories/task_repository.dart';
import 'package:hoque_family_chores/domain/usecases/task/approve_task_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

final _me = UserId('kid1');
final _sibling = UserId('kid2');
final _parent = UserId('parent1');
final _familyId = FamilyId('fam1');
final _taskId = TaskId('task1');

Task _pending({required UserId? assignedTo}) => Task(
      id: _taskId,
      title: 'Tidy room',
      description: '',
      status: TaskStatus.pendingApproval,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedTo,
      createdAt: DateTime(2026, 7, 16),
      points: Points(100),
      tags: const [],
      familyId: _familyId,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(TaskId('fallback'));
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(Points(0));
  });

  late _MockTaskRepository tasks;

  setUp(() {
    tasks = _MockTaskRepository();
    when(() => tasks.getTask(_familyId, _taskId))
        .thenAnswer((_) async => _pending(assignedTo: _me));
    when(() => tasks.approveTask(any(), any())).thenAnswer((_) async {});
    when(() => tasks.rejectTask(any(), any())).thenAnswer((_) async {});
  });

  // Who may approve (a non-parent can't approve their own work; a parent may)
  // is now enforced in the approveTask Cloud Function and covered by the
  // emulator suite (test/rules/functions_economy.test.mjs). Here we only prove
  // the use case delegates the approval to the repository (which calls the
  // Function) and promotes/clears the photos afterwards.
  group('approving', () {
    test('a sibling can approve — the family is peers, not a hierarchy',
        () async {
      final result = await ApproveTaskUseCase(tasks)(
        taskId: _taskId,
        approverId: _sibling,
        familyId: _familyId,
      );

      expect(result.isRight(), isTrue);
      verify(() => tasks.approveTask(_familyId, _taskId)).called(1);
    });

    test('a parent can still approve', () async {
      final result = await ApproveTaskUseCase(tasks)(
        taskId: _taskId,
        approverId: _parent,
        familyId: _familyId,
      );
      expect(result.isRight(), isTrue);
    });
  });

  // Rejecting is NOT guarded in the domain, deliberately.
  //
  // RejectTaskUseCase takes no rejector — it has no idea who is acting — so
  // guarding it means threading a new parameter through four call sites. The
  // exploit that justifies that cost does not exist here: rejecting your own
  // task sends it back to yourself, which `uncompleteTask` already permits
  // outright. No stars are minted, nothing is gained.
  //
  // The UI hides Reject from the assignee alongside Approve, so it does not
  // come up in practice. That is a weaker guarantee than approval has, and it
  // is a deliberate asymmetry rather than an oversight: the guard exists where
  // the money is.
}
