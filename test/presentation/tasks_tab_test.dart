import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

Future<void> _pumpMainScreenSignedIn(WidgetTester tester) async {
  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: MainScreen()),
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
}
