// TaskDetailsScreen(actingAs: child) is a chore opened from the child view on
// a parent's phone: the screen acts as the child, not as the signed-in parent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/stop_repeating_button.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

final _familyId = FamilyId('family_1');

final _kid = User(
  id: UserId('kid'),
  name: 'Amira',
  familyId: _familyId,
  role: UserRole.child,
  points: Points(30),
  joinedAt: DateTime(2026),
  updatedAt: DateTime(2026),
  isManaged: true,
);

final _task = Task(
  id: TaskId('task1'),
  title: 'Mop the kitchen floor',
  description: '',
  status: TaskStatus.assigned,
  difficulty: TaskDifficulty.easy,
  dueDate: DateTime(2026, 8, 20),
  assignedToId: UserId('kid'),
  createdById: UserId('mock_google_uid'),
  createdAt: DateTime(2026, 8, 1),
  points: Points(10),
  tags: const [],
  familyId: _familyId,
);

/// Pumps the screen with a parent signed in, optionally acting as [_kid].
Future<void> _pump(WidgetTester tester, {User? actingAs, Task? task}) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    userRepositoryProvider.overrideWith((_) => users),
    familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
    taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
    notificationRepositoryProvider
        .overrideWith((_) => MockNotificationRepository()),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: appLightTheme,
      home: TaskDetailsScreen(task: task ?? _task, actingAs: actingAs),
    ),
  ));
  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId('mock_google_uid'));
    await users.updateUserProfile(
      profile!.copyWith(familyId: _familyId, role: UserRole.parent),
    );
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets("acting as the child offers the child's Done, no parent menu",
      (tester) async {
    await _pump(tester, actingAs: _kid);

    expect(find.text("I've done it!"), findsOneWidget);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets(
      'acting as anyone hides the parent-only admin UI, whatever their role',
      (tester) async {
    // Managed means child, but the screen must not lean on the acting
    // profile's role: the person holding the phone is not the parent.
    final oddProfile = _kid.copyWith(role: UserRole.parent);
    await _pump(tester,
        actingAs: oddProfile, task: _task.copyWith(ruleId: 'rule1'));

    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byType(StopRepeatingButton), findsNothing);
  });

  testWidgets('without actingAs the parent gets the parent menu, not Done',
      (tester) async {
    await _pump(tester);

    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    expect(find.text("I've done it!"), findsNothing);
  });

  testWidgets('without actingAs the parent can stop a recurring chore',
      (tester) async {
    await _pump(tester, task: _task.copyWith(ruleId: 'rule1'));

    expect(find.byType(StopRepeatingButton), findsOneWidget);
  });
}
