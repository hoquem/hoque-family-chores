// Characterization tests for the action row of TaskListTile.
//
// The widget has six task-status arms and several role/ownership branches.
// These tests pin the current behavior so future refactors do not silently
// drop or add actions. They are black-box: assert on visible labels/icons,
// not on internal state.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';

const _iphoneSe = Size(320, 568);
final _me = UserId('kid1');
final _sibling = UserId('kid2');
final _familyId = FamilyId('fam1');

User _viewer() => User(
      id: _me,
      name: 'Aisha',
      email: Email('aisha@example.com'),
      familyId: _familyId,
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Task _task({
  required TaskStatus status,
  UserId? assignedToId,
  UserId? createdById,
  bool requiresPhotoProof = false,
}) =>
    Task(
      id: TaskId('task1'),
      title: 'Mop the kitchen floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedToId,
      createdById: createdById ?? _me,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: requiresPhotoProof,
    );

Future<void> _pumpTile(
  WidgetTester tester, {
  required TaskStatus status,
  UserId? assignedToId,
  UserId? createdById,
  bool requiresPhotoProof = false,
}) async {
  tester.view.physicalSize = _iphoneSe;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: appLightTheme,
        home: Scaffold(
          body: TaskListTile(
            task: _task(
              status: status,
              assignedToId: assignedToId,
              createdById: createdById,
              requiresPhotoProof: requiresPhotoProof,
            ),
            user: _viewer(),
            onToggleStatus: (_) {},
            onReturnToAvailable: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('available task', () {
    testWidgets('created by someone else shows "I\'ll do it!"', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.available, createdById: _sibling);
      expect(find.text("I'll do it!"), findsOneWidget);
    });

    testWidgets('created by me has no action (cannot self-assign)',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.available, createdById: _me);
      expect(find.text("I'll do it!"), findsNothing);
    });
  });

  group('assigned task', () {
    testWidgets('assigned to me without photo proof offers Done and hand-back',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.assigned,
          assignedToId: _me,
          requiresPhotoProof: false);
      expect(find.text("I've done it!"), findsOneWidget);
      expect(find.byIcon(Icons.assignment_return), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('assigned to me with photo proof offers Start and hand-back',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.assigned,
          assignedToId: _me,
          requiresPhotoProof: true);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_return), findsOneWidget);
      expect(find.text("I've done it!"), findsNothing,
          reason: 'Done in the assigned arm would let a child finish without '
              'ever taking the before photo');
    });

    testWidgets('assigned to someone else has no action', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.assigned, assignedToId: _sibling);
      expect(find.text("I've done it!"), findsNothing);
      expect(find.text('Start'), findsNothing);
      expect(find.byIcon(Icons.assignment_return), findsNothing);
    });
  });

  group('in progress task', () {
    testWidgets('assigned to me offers Done and hand-back', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.inProgress,
          assignedToId: _me,
          requiresPhotoProof: true);
      expect(find.text("I've done it!"), findsOneWidget);
      expect(find.byIcon(Icons.assignment_return), findsOneWidget);
    });

    testWidgets('assigned to someone else has no action', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.inProgress, assignedToId: _sibling);
      expect(find.text("I've done it!"), findsNothing);
      expect(find.byIcon(Icons.assignment_return), findsNothing);
    });
  });

  group('pending approval task', () {
    testWidgets('when I am not the doer, offers Give stars and Send back',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.pendingApproval,
          assignedToId: _sibling);
      expect(find.text('Give stars ⭐'), findsOneWidget);
      expect(find.text('Send back'), findsOneWidget);
    });

    testWidgets('when I am the doer, has no approval action', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.pendingApproval, assignedToId: _me);
      expect(find.text('Give stars ⭐'), findsNothing);
      expect(find.text('Send back'), findsNothing);
    });
  });

  group('needs revision task', () {
    testWidgets('assigned to me offers Send again', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.needsRevision, assignedToId: _me);
      expect(find.text('Send again'), findsOneWidget);
      expect(find.text("I've done it!"), findsNothing);
    });

    // Behaviour change, 2026-08-06. The tile used to offer only Send again
    // here, while the task-details screen offered a way out as well. The
    // tile's own reasoning for inProgress — an arm with no escape "would trap
    // a child who cannot do the chore after all" — applies identically to a
    // chore that was sent back, so the tile gained the escape rather than the
    // detail screen losing it. Rule now lives in taskActionsFor.
    // Matched by tooltip rather than icon. This is the state where the glyphs
    // nearly collided: StatusPill uses Icons.undo for needsRevision
    // (status_pill.dart:58, per DESIGN.md:205), which is why hand-back moved to
    // Icons.assignment_return. The tooltip names the action and cannot collide.
    testWidgets('assigned to me can also hand it back', (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.needsRevision, assignedToId: _me);
      expect(
          find.byTooltip("Can't do it — return to available"), findsOneWidget);
    });

    testWidgets('assigned to someone else shows warning icon only',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.needsRevision, assignedToId: _sibling);
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.text('Send again'), findsNothing);
    });
  });

  group('completed task', () {
    testWidgets('shows Done status and check-circle icon in action row, no actions',
        (tester) async {
      await _pumpTile(tester,
          status: TaskStatus.completed, assignedToId: _sibling);
      expect(find.text('Done'), findsOneWidget);
      // The StatusPill also uses Icons.check_circle, so scope to the action
      // row (the only AnimatedSwitcher in the tile).
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == Icons.check_circle &&
              widget.size == 24,
        ),
        findsOneWidget,
      );
      expect(find.text("I'll do it!"), findsNothing);
      expect(find.text('Give stars ⭐'), findsNothing);
    });
  });
}
