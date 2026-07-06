import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';

import '../../mocks/mock_auth_repository.dart';
import '../../mocks/mock_task_repository.dart';
import '../../mocks/mock_user_repository.dart';
import '../../mocks/mock_family_repository.dart';
import '../../mocks/mock_notification_repository.dart';
import '../../mocks/mock_task_completion_repository.dart';

/// Shared test context accessible from all BDD step files.
class TaskTestContext {
  static TaskTestContext? _instance;

  late MockAuthRepository mockAuthRepository;
  late MockTaskRepository mockTaskRepository;
  late MockUserRepository mockUserRepository;
  late MockFamilyRepository mockFamilyRepository;
  late MockNotificationRepository mockNotificationRepository;
  late MockTaskCompletionRepository mockTaskCompletionRepository;

  User? currentUser;

  static TaskTestContext get instance {
    _instance ??= TaskTestContext();
    return _instance!;
  }

  static void reset() {
    _instance = null;
  }
}

/// Test users.
final testParentUser = User(
  id: UserId('user_1'),
  name: 'John Doe',
  email: Email('john@example.com'),
  photoUrl: null,
  familyId: FamilyId('family_1'),
  role: UserRole.parent,
  points: Points(150),
  joinedAt: DateTime.now().subtract(const Duration(days: 30)),
  updatedAt: DateTime.now(),
);

final testChildUser = User(
  id: UserId('user_2'),
  name: 'Jane Smith',
  email: Email('jane@example.com'),
  photoUrl: null,
  familyId: FamilyId('family_1'),
  role: UserRole.child,
  points: Points(75),
  joinedAt: DateTime.now().subtract(const Duration(days: 25)),
  updatedAt: DateTime.now(),
);

/// Gets the ProviderContainer from the widget tree.
ProviderContainer _container(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(MaterialApp)),
  );
}

/// Pumps the TaskListScreen with mock provider overrides and sets the
/// auth state to an authenticated parent user.
Future<void> pumpTestApp(WidgetTester tester, {User? user}) async {
  // Use a wide viewport to avoid layout overflow in long dropdown labels.
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final ctx = TaskTestContext.instance;
  ctx.mockAuthRepository = MockAuthRepository();
  ctx.mockTaskRepository = MockTaskRepository();
  ctx.mockUserRepository = MockUserRepository();
  ctx.mockFamilyRepository = MockFamilyRepository();
  ctx.mockNotificationRepository = MockNotificationRepository();
  ctx.mockTaskCompletionRepository = MockTaskCompletionRepository();
  ctx.currentUser = user ?? testParentUser;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith((_) => ctx.mockAuthRepository),
        taskRepositoryProvider.overrideWith((_) => ctx.mockTaskRepository),
        userRepositoryProvider.overrideWith((_) => ctx.mockUserRepository),
        familyRepositoryProvider.overrideWith((_) => ctx.mockFamilyRepository),
        notificationRepositoryProvider
            .overrideWith((_) => ctx.mockNotificationRepository),
        taskCompletionRepositoryProvider
            .overrideWith((_) => ctx.mockTaskCompletionRepository),
      ],
      child: const MaterialApp(
        home: TaskListScreen(),
      ),
    ),
  );

  // Set the auth state to authenticated with the test user.
  _setAuthState(tester, ctx.currentUser!);

  // Let the async providers (task loading) settle.
  await tester.pumpAndSettle();
}

/// Sets the auth state directly on the notifier.
void _setAuthState(WidgetTester tester, User user) {
  final authNotifier = _container(tester).read(authNotifierProvider.notifier);
  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  authNotifier.state = AuthState(
    status: AuthStatus.authenticated,
    user: user,
  );
}

/// Switches the authenticated user in the running test app.
Future<void> switchUser(WidgetTester tester, User user) async {
  TaskTestContext.instance.currentUser = user;
  _setAuthState(tester, user);
  await tester.pumpAndSettle();
}

/// Forces the task list provider to re-fetch from the mock repo.
Future<void> refreshTaskList(WidgetTester tester) async {
  final user = TaskTestContext.instance.currentUser!;
  // Use refresh() instead of invalidate() to force an immediate re-read.
  _container(tester).refresh(taskListNotifierProvider(user.familyId));
  await tester.pumpAndSettle();
}

/// Runs an async callback on the real event loop (bypasses the test clock).
/// Use this for mock repository methods that contain [Future.delayed].
Future<T> runReal<T>(WidgetTester tester, Future<T> Function() fn) async {
  late T result;
  await tester.runAsync(() async {
    result = await fn();
  });
  return result;
}

/// Injects a task into the mock repo and refreshes the task list UI.
Future<void> injectTask(WidgetTester tester, Task task) async {
  final ctx = TaskTestContext.instance;
  // Use sync add to avoid test-clock issues with Future.delayed.
  ctx.mockTaskRepository.addTaskSync(task);
  await refreshTaskList(tester);
}
