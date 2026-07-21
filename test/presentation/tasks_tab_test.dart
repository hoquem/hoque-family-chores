import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/task_list_tile.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

/// An unclaimed chore someone else created — so [_uid] is free to claim it
/// (a creator can't claim their own).
Task _availableTask({required String id, required String title}) => Task(
      id: TaskId(id),
      title: title,
      description: '',
      status: TaskStatus.available,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 7, 21),
      assignedToId: null,
      createdById: UserId('someone_else'),
      createdAt: DateTime(2026, 7, 20),
      completedAt: null,
      points: Points(10),
      tags: const [],
      familyId: FamilyId('family_1'),
    );

Future<void> _pumpMainScreenSignedIn(
  WidgetTester tester, {
  MockTaskRepository? taskRepository,
  Widget home = const MainScreen(),
}) async {
  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider
          .overrideWith((_) => taskRepository ?? MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: home),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users
        .updateUserProfile(profile!.copyWith(familyId: FamilyId('family_1')));
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the Tasks tab offers adding and managing tasks',
      (tester) async {
    await _pumpMainScreenSignedIn(tester);

    await tester.tap(find.text('Tasks'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Managing: the filter menu for all task views must be available.
    expect(find.byType(PopupMenuButton<TaskFilterType>), findsOneWidget,
        reason: 'the Tasks tab must expose the task filters');

    // Adding: the add-task button must always be reachable.
    expect(find.byType(FloatingActionButton), findsOneWidget,
        reason: 'the Tasks tab must let the user create a task');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byType(AddTaskScreen), findsOneWidget);
  });

  testWidgets('claiming a chore from the Tasks tab takes it, no false failure',
      (tester) async {
    // Regression: tapping "I'll do it!" on the Tasks tab used to route through
    // the available-tasks notifier, which isn't loaded on this screen and
    // null-checked its own absent state — so the claim landed server-side but
    // the tile showed "Couldn't take this one". The claim now goes through the
    // task-list notifier the tab actually watches.
    final taskRepo = MockTaskRepository();
    taskRepo.addTaskSync(_availableTask(id: 'chore1', title: 'Wash up'));
    // Pump the Tasks screen directly: it watches the task-list notifier, and
    // crucially NOT the available-tasks notifier — the exact context where the
    // old claim path had no loaded state to null-check.
    await _pumpMainScreenSignedIn(tester,
        taskRepository: taskRepo, home: const TaskListScreen());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Scope to the Wash up tile — the mock seeds other chores too.
    final washUpTile =
        find.ancestor(of: find.text('Wash up'), matching: find.byType(TaskListTile));
    expect(washUpTile, findsOneWidget);
    expect(find.descendant(of: washUpTile, matching: find.text("I'll do it!")),
        findsOneWidget,
        reason: 'an unclaimed chore offers the claim button');

    await tester.tap(
        find.descendant(of: washUpTile, matching: find.text("I'll do it!")));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining("Couldn't take this one"), findsNothing,
        reason: 'the claim went through — no false failure');
    expect(find.descendant(of: washUpTile, matching: find.text("I'll do it!")),
        findsNothing,
        reason: 'the chore is no longer up for grabs once claimed');
    expect(find.descendant(of: washUpTile, matching: find.text('Assigned')),
        findsOneWidget,
        reason: 'the claimed chore now shows as assigned to the claimer');
  });
}
