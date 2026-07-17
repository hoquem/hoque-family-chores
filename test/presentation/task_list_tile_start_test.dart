// The bypass tests.
//
// A photo-proof task must be startable and NOT directly completable: the
// assigned arm has always rendered "Done", and adding "Start" beside it would
// leave the old path open. A child taps Done, no before photo is ever taken,
// and the whole feature is decorative while every test stays green.
//
// So the assertion that matters here is `Done is ABSENT`, not `Start is
// present`. The domain-level twin of this lives in the complete-task use case,
// because the UI is not a security boundary.
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
final _familyId = FamilyId('fam1');

User _kid() => User(
      id: _me,
      name: 'Aisha',
      email: Email('aisha@example.com'),
      familyId: _familyId,
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Task _task({required bool requiresPhotoProof}) => Task(
      id: TaskId('task1'),
      title: 'Mop the kitchen floor',
      description: '',
      status: TaskStatus.assigned,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: _me,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: requiresPhotoProof,
    );

Future<void> _pumpTile(WidgetTester tester, {required bool proof}) async {
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
            task: _task(requiresPhotoProof: proof),
            user: _kid(),
            onToggleStatus: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('a photo-proof task', () {
    testWidgets('offers Start', (tester) async {
      await _pumpTile(tester, proof: true);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('does NOT offer Done — the before photo cannot be skipped',
        (tester) async {
      await _pumpTile(tester, proof: true);
      expect(find.text('Done'), findsNothing,
          reason: 'Done in the assigned arm bypasses the before photo entirely; '
              'Start must replace it, not sit beside it');
    });

    testWidgets('can still be handed back', (tester) async {
      await _pumpTile(tester, proof: true);
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });
  });

  group('an ordinary task is untouched', () {
    testWidgets('still offers Done, and no Start', (tester) async {
      await _pumpTile(tester, proof: false);
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });
  });
}
