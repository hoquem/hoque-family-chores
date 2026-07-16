import 'package:flutter/material.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/add_task_screen.dart';
import 'package:intl/intl.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';

/// Members fail with a non-transient error until [failMembers] is cleared.
class _FailingMembersRepository extends MockFamilyRepository {
  bool failMembers = true;

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async {
    if (failMembers) {
      throw const ServerException('network unreachable', code: 'X');
    }
    return super.getFamilyMembers(familyId);
  }
}

/// Pumps the AddTaskScreen signed in as a parent in family_1.
///
/// Ends after a single frame so tests can observe transient states;
/// call [settle] to let the mock repositories' delays elapse.
Future<void> _pumpAddTaskScreen(
  WidgetTester tester, {
  MockFamilyRepository? familyRepository,
}) async {
  // Use a wide viewport to avoid layout overflow in long dropdown labels.
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider
          .overrideWith((_) => familyRepository ?? MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: AddTaskScreen()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users
        .updateUserProfile(profile!.copyWith(familyId: FamilyId('family_1')));
  });
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('creation screen speaks the same language as the Tasks tab',
      (tester) async {
    await _pumpAddTaskScreen(tester);
    await _settle(tester);

    expect(find.text('Add New Task'), findsOneWidget);
    expect(find.text('Task Title'), findsOneWidget);
    expect(find.text('Create Task'), findsOneWidget);
    expect(find.textContaining('Quest'), findsNothing,
        reason: 'the rest of the app calls them tasks');
    expect(find.textContaining('quest'), findsNothing,
        reason: 'the rest of the app calls them tasks');

    // The empty-title validation message matches the field label.
    await tester.tap(find.text('Create Task'));
    await tester.pump();
    expect(find.text('Please enter a task title'), findsOneWidget);
  });

  testWidgets('due date field reads as a deadline, not a duration',
      (tester) async {
    await _pumpAddTaskScreen(tester);
    await _settle(tester);

    expect(find.text('Due Date'), findsOneWidget);
    expect(find.textContaining('Approximate Time to Complete'), findsNothing,
        reason: 'a due date is a deadline, not a time-to-complete estimate');
  });

  testWidgets('members are loading: the assignee field says so',
      (tester) async {
    await _pumpAddTaskScreen(tester);

    // The mock repository delays 100ms, so the first frame is the
    // loading state.
    expect(find.text('Loading family members…'), findsOneWidget,
        reason: 'a silent empty dropdown is indistinguishable from '
            'having no family members');

    await _settle(tester);
    expect(find.text('Loading family members…'), findsNothing);
  });

  testWidgets('failed members load shows an error with a working Retry',
      (tester) async {
    final family = _FailingMembersRepository();
    await _pumpAddTaskScreen(tester, familyRepository: family);
    await _settle(tester);

    expect(find.textContaining('Could not load family members'),
        findsOneWidget,
        reason: 'a failed load must not silently look like an empty family');
    expect(find.text('Retry'), findsOneWidget);

    family.failMembers = false;
    await tester.tap(find.text('Retry'));
    await _settle(tester);

    expect(find.textContaining('Could not load family members'), findsNothing);
    expect(find.text('Assign To (Optional)'), findsOneWidget,
        reason: 'the assignee dropdown must come back after a retry');
  });

  testWidgets('a chosen due date can be cleared again', (tester) async {
    await _pumpAddTaskScreen(tester);
    await _settle(tester);

    // Pick today's date via the date picker dialog.
    await tester.tap(find.text('Select a date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final today = DateFormat('MMM d, y').format(DateTime.now());
    expect(find.text(today), findsOneWidget);
    expect(find.text('Select a date'), findsNothing);

    // Clear it: the field must return to its unset state.
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    expect(find.text('Select a date'), findsOneWidget);
    expect(find.text(today), findsNothing);
  });
}
