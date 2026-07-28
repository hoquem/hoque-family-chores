// A completed chore says who checked it — the transparency half of the
// trust-based approval model: anyone but the doer signs the work off, so the
// sign-off must be visible to the whole family.
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

Task _completedTask({UserId? approvedBy}) => Task(
      id: TaskId('task1'),
      title: 'Mop the kitchen floor',
      description: '',
      status: TaskStatus.completed,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: _sibling,
      approvedBy: approvedBy,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
    );

Future<void> _pumpTile(WidgetTester tester, {UserId? approvedBy}) async {
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
            task: _completedTask(approvedBy: approvedBy),
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
  group('a completed chore', () {
    testWidgets('shows who checked it when I was the approver', (tester) async {
      await _pumpTile(tester, approvedBy: _me);
      expect(find.text('Checked by: you'), findsOneWidget,
          reason: 'peer approval only builds trust if the family can see '
              'who signed the work off');
    });

    testWidgets('shows nothing about the check when nobody was recorded',
        (tester) async {
      // Tasks completed before approvedBy existed have no approver on record;
      // showing a made-up one would be worse than showing none.
      await _pumpTile(tester);
      expect(find.textContaining('Checked by'), findsNothing);
    });
  });
}
