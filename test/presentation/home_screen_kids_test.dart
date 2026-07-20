import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';
import 'package:hoque_family_chores/presentation/widgets/home/leaderboard_card.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _me = UserId(_uid);
final _familyId = FamilyId('family_1');

Task _task({
  required String id,
  required String title,
  UserId? assignedTo,
  TaskStatus status = TaskStatus.assigned,
  DateTime? due,
  DateTime? completedAt,
  int points = 10,
}) {
  return Task(
    id: TaskId(id),
    title: title,
    description: '',
    status: status,
    difficulty: TaskDifficulty.easy,
    dueDate: due ?? DateTime.now(),
    assignedToId: assignedTo ?? _me,
    createdById: UserId('user_1'),
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    completedAt: completedAt,
    points: Points(points),
    tags: const [],
    familyId: _familyId,
  );
}

User _member(String id, String name) {
  return User(
    id: UserId(id),
    name: name,
    // Derived from the name: the Email value object rejects underscores,
    // which ids like mock_google_uid contain.
    email: Email('${name.split(' ').first.toLowerCase()}@example.com'),
    photoUrl: null,
    familyId: _familyId,
    role: UserRole.child,
    points: Points(0),
    joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
}

/// Returns a fixed member list regardless of internal state.
class _SeededFamilyRepository extends MockFamilyRepository {
  _SeededFamilyRepository(this.members);
  final List<User> members;

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async => members;
}

/// Tasks fail with a non-transient error until [failTasks] is cleared.
class _FailingTaskRepository extends MockTaskRepository {
  bool failTasks = true;

  @override
  Future<List<Task>> getTasksForFamily(FamilyId familyId) async {
    if (failTasks) {
      throw const ServerException('network unreachable', code: 'X');
    }
    return super.getTasksForFamily(familyId);
  }

  @override
  Stream<List<Task>> streamTasks(FamilyId familyId) async* {
    // Home watches the stream now, so the failure must arrive that way too.
    if (failTasks) {
      throw const ServerException('network unreachable', code: 'X');
    }
    yield* super.streamTasks(familyId);
  }
}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  required UserRole role,
  List<Task> tasks = const [],
  List<User> extraMembers = const [],
  MockTaskRepository? taskRepository,
  Widget home = const HomeScreen(),
}) async {
  // Phone width, generous height: the kids' home hub is a long scroll and the
  // tests assert on cards below the fold, but the width must be one a child
  // actually holds.
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final taskRepo = taskRepository ?? MockTaskRepository();
  for (final task in tasks) {
    taskRepo.addTaskSync(task);
  }

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => _SeededFamilyRepository([
            // The signed-in user plus any extras.
            _member(_uid, 'Maya Hoque'),
            ...extraMembers,
          ])),
      taskRepositoryProvider.overrideWith((_) => taskRepo),
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
    final profile = await users.getUserProfile(_me);
    await users.updateUserProfile(profile!.copyWith(
      name: 'Maya Hoque',
      familyId: _familyId,
      role: role,
      points: Points(150),
    ));
  });
  // Three frames: auth propagates, the task list loads, then the members
  // provider (first watched once tasks have data) delivers.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));

  return container;
}

void main() {
  testWidgets('a child sees greeting, progress, missions, and the leaderboard',
      (tester) async {
    await _pumpHome(
      tester,
      role: UserRole.child,
      extraMembers: [_member('zafir', 'Zafir'), _member('priya', 'Priya')],
      tasks: [
        _task(id: 'cat', title: 'Feed the cat', points: 10),
        _task(id: 'plants', title: 'Water the plants', points: 25),
        // My completion today: starts a streak.
        _task(
            id: 'mine-done',
            title: 'Make the bed',
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            points: 10),
        // Siblings' stars this week.
        _task(
            id: 'z1',
            title: 'Mow the lawn',
            assignedTo: UserId('zafir'),
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            points: 60),
        _task(
            id: 'p1',
            title: 'Vacuum',
            assignedTo: UserId('priya'),
            status: TaskStatus.completed,
            completedAt: DateTime.now(),
            points: 25),
      ],
    );

    // Greeting header.
    expect(find.text('Hi Maya! 👋'), findsOneWidget);
    expect(find.text('Level 2 • 150 ⭐'), findsOneWidget);

    // Progress and streak.
    expect(find.text('50 ⭐ to next level'), findsOneWidget);
    expect(find.text('1-day streak 🔥'), findsOneWidget);

    // Today's missions with star rewards.
    expect(find.text("Today's Missions"), findsOneWidget);
    expect(find.text('Feed the cat'), findsOneWidget);
    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.text('+10 ⭐'), findsOneWidget);
    expect(find.text('+25 ⭐'), findsOneWidget);

    // Weekly leaderboard, best first, with medals.
    expect(find.text("This Week's Stars"), findsOneWidget);
    final rankedNames = tester
        .widgetList<ListTile>(find.descendant(
            of: find.byType(LeaderboardCard),
            matching: find.byType(ListTile)))
        .map((tile) => (tile.title as Text).data)
        .toList();
    expect(rankedNames, ['Zafir', 'Priya', 'Maya Hoque']);
    expect(find.text('🥇'), findsOneWidget);
    expect(find.text('60 ⭐'), findsOneWidget);
  });

  testWidgets(
      'completing the last mission celebrates and shows it waiting for approval',
      (tester) async {
    await _pumpHome(
      tester,
      role: UserRole.child,
      tasks: [_task(id: 'cat', title: 'Feed the cat', points: 10)],
    );

    expect(find.text('All done for today! 🎉'), findsNothing);

    await tester.tap(find.byTooltip('Mark as done'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1)); // celebration animation

    expect(find.text('Waiting for approval ⏳'), findsOneWidget);
    expect(find.text('All done for today! 🎉'), findsOneWidget);
  });

  testWidgets('a day without missions is calm, not celebratory',
      (tester) async {
    await _pumpHome(tester, role: UserRole.child);

    expect(find.text('No missions today 🎈'), findsOneWidget);
    expect(find.text('All done for today! 🎉'), findsNothing);
  });

  testWidgets(
      'a parent sees the approval queue instead of the leaderboard and '
      'taps through to the filtered Tasks tab', (tester) async {
    final container = await _pumpHome(
      tester,
      role: UserRole.parent,
      home: const MainScreen(),
      tasks: [
        _task(
            id: 'kid-done',
            title: 'Feed the cat',
            assignedTo: UserId('zafir'),
            status: TaskStatus.pendingApproval,
            completedAt: DateTime.now()),
      ],
    );

    expect(find.text('Needs your approval'), findsOneWidget);
    expect(find.text('1 task waiting'), findsOneWidget);
    expect(find.text("This Week's Stars"), findsNothing);

    await tester.tap(find.text('Needs your approval'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Lands on the Tasks tab with the Needs Approval filter active.
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Tasks')),
      findsOneWidget,
    );
    expect(container.read(taskFilterNotifierProvider),
        TaskFilterType.pendingApproval);

    // The list itself must be filtered: only the pending task is shown,
    // not the seeded available/completed mock tasks.
    expect(find.text('Feed the cat'), findsOneWidget);
    expect(find.text('Clean the kitchen'), findsNothing);
    expect(find.text('Take out trash'), findsNothing);
  });

  testWidgets('failed task load shows an error with a working Retry',
      (tester) async {
    final taskRepo = _FailingTaskRepository();
    await _pumpHome(tester, role: UserRole.child, taskRepository: taskRepo);

    expect(find.textContaining('Could not load tasks'), findsOneWidget,
        reason: 'a failed load must not look like a free day');
    expect(find.text('Retry'), findsOneWidget);

    taskRepo.failTasks = false;
    await tester.tap(find.text('Retry'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Could not load tasks'), findsNothing);
    expect(find.text('No missions today 🎈'), findsOneWidget);
  });
}
