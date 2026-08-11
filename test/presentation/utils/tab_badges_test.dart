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

    // The invariant this file exists for: the badge counts exactly what the
    // buttons offer. It was written when a parent's own submission was badged
    // but unapprovable — the badge nagging for work the app refused to allow.
    // TASK-500 moved the line rather than the invariant: a parent may now sign
    // off their own chore, so it is real work and it counts.
    test('counts their own submission — a parent may sign that off', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.parent),
        tasks: [_task(TaskStatus.pendingApproval, assignedTo: _me)],
        unreadNotifications: 0,
      );
      expect(counts.chores, 1,
          reason: 'the badge must agree with the buttons: taskActionsFor now '
              'offers a parent Approve on their own submission');
    });

    // The same invariant from the other side: a child's own submission is
    // still not theirs to sign off, so it must not be badged at them.
    test("a child's own submission is still not badged at them", () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.child),
        tasks: [_task(TaskStatus.pendingApproval, assignedTo: _me)],
        unreadNotifications: 0,
      );
      expect(counts.chores, 0);
    });

    test('counts both its own and someone else\'s for a parent', () {
      final counts = tabBadgeCounts(
        viewer: _viewer(UserRole.parent),
        tasks: [
          _task(TaskStatus.pendingApproval, assignedTo: _sibling),
          _task(TaskStatus.pendingApproval, assignedTo: _me),
        ],
        unreadNotifications: 0,
      );
      expect(counts.chores, 2);
    });
  });
}
