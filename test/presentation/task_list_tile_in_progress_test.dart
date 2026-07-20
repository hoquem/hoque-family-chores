// A started task must be escapable.
//
// TaskStatus.inProgress was added with its action arm returning null, so a
// child who tapped Start would be stranded: no Done, no way back. That is the
// exact dead end Start exists to prevent, and no data-level test would catch
// it — the round trip never renders a tile.
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
final _someoneElse = UserId('kid2');
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

Task _startedTask({UserId? assignedTo}) => Task(
      id: TaskId('task1'),
      title: 'Mop the kitchen floor',
      description: '',
      status: TaskStatus.inProgress,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 20),
      assignedToId: assignedTo ?? _me,
      createdAt: DateTime(2026, 7, 16),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: true,
      beforePhotoUrl: 'https://example.com/before.jpg',
    );

Future<void> _pumpTile(WidgetTester tester, {UserId? assignedTo}) async {
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
            task: _startedTask(assignedTo: assignedTo),
            user: _kid(),
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
  group('a task I have started', () {
    testWidgets('can be finished', (tester) async {
      await _pumpTile(tester);
      expect(find.text("I've done it!"), findsOneWidget,
          reason: 'without Done, starting a task strands the child in a state '
              'with no way out — the dead end Start exists to prevent');
    });

    testWidgets('can be handed back', (tester) async {
      await _pumpTile(tester);
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('shows it is in progress', (tester) async {
      await _pumpTile(tester);
      expect(find.text('On it'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle), findsWidgets);
    });
  });

  group("someone else's started task", () {
    testWidgets('offers me nothing', (tester) async {
      await _pumpTile(tester, assignedTo: _someoneElse);
      expect(find.text("I've done it!"), findsNothing);
      expect(find.byIcon(Icons.undo), findsNothing);
    });
  });
}
