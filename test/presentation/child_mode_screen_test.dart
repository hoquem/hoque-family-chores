import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/screens/child_mode_screen.dart';
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';
import '../utils/task_factory.dart';

final _familyId = FamilyId('family_1');

User _kid({bool managed = true}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(12),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// Serves a fixed task list and records who completes / claims, so tests stay
/// off Firebase and can assert the actions act as the child.
class _RecordingTaskRepository extends MockTaskRepository {
  _RecordingTaskRepository(this.seed);

  final List<Task> seed;
  final claims = <(TaskId, UserId)>[];
  final completions = <TaskId>[];

  @override
  Future<List<Task>> getTasksForFamily(FamilyId familyId) async => seed;

  @override
  Stream<List<Task>> streamTasks(FamilyId familyId) => Stream.value(seed);

  @override
  Future<Task?> getTask(FamilyId familyId, TaskId taskId) async =>
      seed.where((t) => t.id == taskId).firstOrNull;

  @override
  Future<void> claimTask(FamilyId familyId, TaskId taskId, UserId userId) async {
    claims.add((taskId, userId));
  }

  @override
  Future<void> completeTask(FamilyId familyId, TaskId taskId) async {
    completions.add(taskId);
  }
}

class _NoAnalytics extends Analytics {
  @override
  Future<void> log(
    AnalyticsEventName name, {
    required String userId,
    String? familyId,
    Map<String, Object?> params = const {},
  }) async {}
}

class _SilentSoundPlayer implements SoundPlayer {
  @override
  Future<void> play(String asset) async {}
}

Future<_RecordingTaskRepository> _pump(
  WidgetTester tester, {
  required Stream<User?> kid,
  required List<Task> tasks,
}) async {
  final repo = _RecordingTaskRepository(tasks);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      // ChildModeScreen reads the signed-in parent for analytics, which
      // builds AuthNotifier; keep it off real Firebase.
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
      taskRepositoryProvider.overrideWith((_) => repo),
      analyticsProvider.overrideWithValue(_NoAnalytics()),
      soundPlayerProvider.overrideWithValue(_SilentSoundPlayer()),
      memberProfileProvider(UserId('kid')).overrideWith((_) => kid),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChildModeScreen(childId: UserId('kid'), parentName: 'Mum'),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows only the child\'s chores and the up-for-grabs ones', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
      testTask(id: 'b', title: 'Mum chore', status: TaskStatus.assigned, assignedTo: 'mum'),
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);

    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Tidy room'), findsOneWidget);
    expect(find.text('Feed cat'), findsOneWidget);
    expect(find.text('Mum chore'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Take'), findsOneWidget);
  });

  testWidgets('Done completes the chore as the child', (tester) async {
    final repo = await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
    ]);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // The use case only completes when assignedToId == the acting user, so a
    // completion proves the child (not the parent) was the actor.
    expect(repo.completions, [TaskId('a')]);
  });

  testWidgets('Take claims the chore for the child', (tester) async {
    final repo = await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);
    await tester.tap(find.text('Take'));
    await tester.pumpAndSettle();
    expect(repo.claims, [(TaskId('c'), UserId('kid'))]);
  });

  testWidgets('Back returns to the parent', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: const []);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself once the child is linked to their own phone', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: const []);
    expect(find.text('Amira'), findsOneWidget);

    kid.add(_kid(managed: false));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself when the child is removed', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: const []);

    kid.add(null);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself if the child is already not managed on open', (tester) async {
    await _pump(tester, kid: Stream.value(_kid(managed: false)), tasks: const []);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a profile load error shows the message and a way back', (tester) async {
    await _pump(tester, kid: Stream.error(Exception('boom')), tasks: const []);
    expect(find.textContaining('boom'), findsOneWidget);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
