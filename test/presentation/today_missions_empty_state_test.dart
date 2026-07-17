// The dead end: a child with nothing assigned opens the app and the app has
// nothing to say. This is the screen PRODUCT.md says should bring them back
// daily, so an empty card is a product failure, not a neutral state.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/today_missions_card.dart';

const _iphoneSe = Size(320, 568);
final _me = UserId('me');
final _familyId = FamilyId('fam1');

Task _task(String id, {TaskStatus status = TaskStatus.available, UserId? owner}) =>
    Task(
      id: TaskId(id),
      title: 'Chore $id',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 15),
      assignedToId: owner,
      createdAt: DateTime(2026, 7, 1),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
    );

Future<List<Task>> _pump(WidgetTester tester, TodayMissions missions) async {
  final claimed = <Task>[];
  tester.view.physicalSize = _iphoneSe;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: appLightTheme,
      home: Scaffold(
        body: TodayMissionsCard(
          missions: missions,
          onComplete: (_) {},
          onClaim: claimed.add,
        ),
      ),
    ),
  );
  await tester.pump();
  return claimed;
}

void main() {
  testWidgets('nothing assigned, but work going spare: offers it',
      (tester) async {
    await _pump(
      tester,
      TodayMissions(
        toDo: const [],
        waiting: const [],
        done: const [],
        claimable: [_task('a'), _task('b')],
      ),
    );

    expect(find.text('Nothing assigned — grab one?'), findsOneWidget);
    expect(find.text('Chore a'), findsOneWidget);
    expect(find.text('No missions today 🎈'), findsNothing,
        reason: 'the balloon is the dead end; it must not appear when there is '
            'something to do');
  });

  testWidgets('tapping picks the task up', (tester) async {
    final claimed = await _pump(
      tester,
      TodayMissions(
        toDo: const [],
        waiting: const [],
        done: const [],
        claimable: [_task('a')],
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();

    expect(claimed.map((t) => t.id.value), ['a']);
  });

  testWidgets('shows at most three — the home screen is a glance',
      (tester) async {
    await _pump(
      tester,
      TodayMissions(
        toDo: const [],
        waiting: const [],
        done: const [],
        claimable: [_task('a'), _task('b'), _task('c'), _task('d')],
      ),
    );

    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(3));
    expect(find.text('Chore d'), findsNothing);
  });

  testWidgets('never offers spare work alongside your own missions',
      (tester) async {
    // Your own list is the point of the card; spare work is a fallback for
    // when it is empty, not a sidebar.
    await _pump(
      tester,
      TodayMissions(
        toDo: [_task('mine', status: TaskStatus.assigned, owner: _me)],
        waiting: const [],
        done: const [],
        claimable: [_task('spare')],
      ),
    );

    expect(find.text('Chore mine'), findsOneWidget);
    expect(find.text('Nothing assigned — grab one?'), findsNothing);
    expect(find.text('Chore spare'), findsNothing);
  });

  testWidgets('never interrupts the finished-everything moment', (tester) async {
    // allDone drives the celebration card. "Grab another!" on top of that
    // reads as nagging and breaks DESIGN.md's One-Celebration Rule.
    await _pump(
      tester,
      TodayMissions(
        toDo: const [],
        waiting: const [],
        done: [_task('done', status: TaskStatus.completed, owner: _me)],
        claimable: [_task('spare')],
      ),
    );

    expect(find.text('Nothing assigned — grab one?'), findsNothing);
    expect(find.text('Chore spare'), findsNothing);
  });

  testWidgets('nothing to do and nothing to take: says so honestly',
      (tester) async {
    await _pump(
      tester,
      const TodayMissions(toDo: [], waiting: [], done: [], claimable: []),
    );

    expect(find.text('No missions today 🎈'), findsOneWidget);
  });
}
