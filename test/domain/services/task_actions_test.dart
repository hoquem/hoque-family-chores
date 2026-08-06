// What a family member may do to a chore, given who they are.
//
// These rules were written twice — once in `task_list_tile.dart` and once in
// `task_details_screen.dart` — and the two copies had already drifted apart:
// the detail screen offers "Give it back" on a sent-back chore, the list tile
// does not. See the `needsRevision` group below for which one won and why.
//
// This is a decision, not a security boundary. The Cloud Functions and
// `firestore.rules` are the real guard; this is what the UI offers, and it must
// agree with them or a child sees a button that fails when tapped.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/task_actions.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

final _me = UserId('kid1');
final _sibling = UserId('kid2');

Task _task({
  required TaskStatus status,
  UserId? assignedTo,
  UserId? createdBy,
  bool requiresPhotoProof = false,
}) =>
    Task(
      id: TaskId('task1'),
      title: 'Tidy room',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 10),
      assignedToId: assignedTo,
      createdById: createdBy,
      createdAt: DateTime(2026, 8, 1),
      points: Points(10),
      tags: const [],
      familyId: FamilyId('fam1'),
      requiresPhotoProof: requiresPhotoProof,
    );

void main() {
  group('an unclaimed chore', () {
    test('is up for grabs by anyone who did not create it', () {
      final task = _task(status: TaskStatus.available, createdBy: _sibling);
      expect(taskActionsFor(task: task, viewerId: _me), [TaskAction.claim]);
    });

    // You cannot claim your own chore; a parent assigns it. Without this a
    // child could create, claim, do and bank a chore with no one else involved.
    test('offers nothing to the person who created it', () {
      final task = _task(status: TaskStatus.available, createdBy: _me);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });
  });

  group('a chore assigned to me', () {
    test('is done directly when it needs no photo proof', () {
      final task = _task(status: TaskStatus.assigned, assignedTo: _me);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.complete, TaskAction.handBack]);
    });

    // Start REPLACES complete rather than joining it. Leaving complete in place
    // would let a child finish without ever taking the before photo, which is
    // the whole point of photo proof. CompleteTaskUseCase enforces the same
    // rule — the UI is not the boundary.
    test('must be started first when it needs photo proof', () {
      final task = _task(
          status: TaskStatus.assigned,
          assignedTo: _me,
          requiresPhotoProof: true);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.start, TaskAction.handBack]);
    });

    test('can be finished or handed back once started', () {
      final task = _task(status: TaskStatus.inProgress, assignedTo: _me);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.complete, TaskAction.handBack]);
    });
  });

  group("someone else's chore", () {
    test('offers me nothing while they are doing it', () {
      final task = _task(status: TaskStatus.assigned, assignedTo: _sibling);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });

    test('offers me nothing while it is in progress', () {
      final task = _task(status: TaskStatus.inProgress, assignedTo: _sibling);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });
  });

  group('a chore waiting for sign-off', () {
    // Anyone in the family may sign off — except the person who did it. Not a
    // parents-only rule: the family is peers. `self_approval_test.dart` pins
    // the server-side half of this.
    test('can be judged by anyone who did not do it', () {
      final task =
          _task(status: TaskStatus.pendingApproval, assignedTo: _sibling);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.approve, TaskAction.sendBack]);
    });

    test('offers nothing to the person who did it', () {
      final task = _task(status: TaskStatus.pendingApproval, assignedTo: _me);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });

    // Bad data: nothing should reach pendingApproval without a doer. Judgeable
    // is the safe reading — the Cloud Function re-checks before paying out, so
    // the worst case is a button that fails, not a star minted from nothing.
    test('with no doer at all is still judgeable, not stuck', () {
      final task = _task(status: TaskStatus.pendingApproval);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.approve, TaskAction.sendBack]);
    });
  });

  group('a chore sent back to me', () {
    // THE DIVERGENCE. task_details_screen.dart:873-876 offers "Give it back" on
    // needsRevision; task_list_tile.dart:587-600 offers only "Send again". The
    // detail screen wins: the tile's own comment for inProgress says an arm
    // with only Done "would trap a child who cannot do the chore after all",
    // and that argument applies identically here. A child who has been sent
    // back a chore they cannot redo must have a way out.
    test('can be resubmitted or handed back', () {
      final task = _task(status: TaskStatus.needsRevision, assignedTo: _me);
      expect(taskActionsFor(task: task, viewerId: _me),
          [TaskAction.resubmit, TaskAction.handBack]);
    });

    test('offers nothing to anyone else', () {
      final task =
          _task(status: TaskStatus.needsRevision, assignedTo: _sibling);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });
  });

  group('an approved chore', () {
    test('is finished — nobody has anything left to do', () {
      final task = _task(status: TaskStatus.completed, assignedTo: _me);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
      expect(taskActionsFor(task: task, viewerId: _sibling), isEmpty);
    });
  });

  group('an unassigned chore in a working state', () {
    // Defensive: a task with no assignee should never be `assigned`, but bad
    // data must not hand a stranger the doer's buttons.
    test('offers nothing to anyone', () {
      final task = _task(status: TaskStatus.assigned);
      expect(taskActionsFor(task: task, viewerId: _me), isEmpty);
    });
  });
}
