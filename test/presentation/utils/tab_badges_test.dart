// What the little red numbers on the tab bar count.
//
// Characterization first: these pin what the badge did when it lived inline in
// MainScreen, including one behaviour marked BUG below. Nothing tested it
// before, so this is the safety net before changing it — not an endorsement.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/utils/tab_badges.dart';

final _me = UserId('kid1');
final _sibling = UserId('kid2');
final _familyId = FamilyId('fam1');

User _viewer(UserRole role) => User(
      id: _me,
      name: 'Aisha',
      email: Email('aisha@example.com'),
      familyId: _familyId,
      role: role,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Task _task(TaskStatus status, {UserId? assignedTo, UserId? createdBy}) => Task(
      id: TaskId('t${status.name}${assignedTo?.value ?? ''}'),
      title: 'Mop the floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 20),
      assignedToId: assignedTo,
      createdById: createdBy ?? _sibling,
      createdAt: DateTime(2026, 8, 1),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
    );

void main() {
  group('the Profile badge', () {
    test('counts unread notifications', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: const [],
        unreadNotifications: 3,
      );
      expect(counts.profile, 3);
    });

    test('is absent when everything has been read', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: const [],
        unreadNotifications: 0,
      );
      expect(counts.profile, 0);
    });
  });

  group('the Chores badge, for someone who is not a parent', () {
    test('counts free chores and their own live work', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: [
          _task(TaskStatus.available),
          _task(TaskStatus.assigned, assignedTo: _me),
          _task(TaskStatus.inProgress, assignedTo: _me),
          _task(TaskStatus.needsRevision, assignedTo: _me),
        ],
        unreadNotifications: 0,
      );
      expect(counts.chores, 4);
    });

    test("ignores work that belongs to someone else", () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: [
          _task(TaskStatus.assigned, assignedTo: _sibling),
          _task(TaskStatus.inProgress, assignedTo: _sibling),
        ],
        unreadNotifications: 0,
      );
      expect(counts.chores, 0);
    });

    test('ignores chores already waiting for sign-off', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: [_task(TaskStatus.pendingApproval, assignedTo: _me)],
        unreadNotifications: 0,
      );
      expect(counts.chores, 0,
          reason: 'submitted work needs nothing further from the doer');
    });
  });

  group('the Chores badge, for a parent', () {
    test('counts chores waiting for sign-off', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.parent),
        tasks: [_task(TaskStatus.pendingApproval, assignedTo: _sibling)],
        unreadNotifications: 0,
      );
      expect(counts.chores, 1);
    });

    // The bug this file was written to fix. A parent who submits their own
    // chore was badged to approve it — but no-self-approval forbids that, and
    // taskActionsFor correctly hides the buttons. The badge was nagging for
    // work the app refuses to let them do.
    test('ignores their own submission — they cannot sign off their own work',
        () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.parent),
        tasks: [_task(TaskStatus.pendingApproval, assignedTo: _me)],
        unreadNotifications: 0,
      );
      expect(counts.chores, 0,
          reason: 'the badge must agree with the buttons: taskActionsFor '
              'offers this viewer nothing on their own submission');
    });

    test('counts only the ones they can actually sign off', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.parent),
        tasks: [
          _task(TaskStatus.pendingApproval, assignedTo: _sibling),
          _task(TaskStatus.pendingApproval, assignedTo: _me),
        ],
        unreadNotifications: 0,
      );
      expect(counts.chores, 1);
    });
  });
}
