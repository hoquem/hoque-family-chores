
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_managed_child_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

/// Analytics no-op so the tests never touch Firebase.
class _NoAnalytics extends Analytics {
  @override
  Future<void> log(
    AnalyticsEventName name, {
    required String userId,
    String? familyId,
    Map<String, Object?> params = const {},
  }) async {}
}

/// Stands in for the app's auth routing: the login stack while signed out, a
/// marker once signed in (the real tabs would pull in unrelated providers).
class _Routing extends ConsumerWidget {
  const _Routing();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authNotifierProvider.select((s) => s.status));
    return status == AuthStatus.authenticated
        ? const Scaffold(body: Text('signed_in_home'))
        : const LoginScreen();
  }
}

/// Opens the link-code screen from the signed-out login stack. The mock
/// repository returns the code as the token and the mock auth signs in with
/// the token as the uid, so entering 'kid_uid' signs in as users/kid_uid.
Future<void> _openLinkScreen(
  WidgetTester tester,
  MockManagedChildRepository repo,
) async {
  final users = MockUserRepository();
  // The mock's simulated network delay never fires under fake async.
  await tester.runAsync(() => users.createUserProfile(User(
    id: UserId('kid_uid'),
    name: 'Amira',
    familyId: FamilyId('family_1'),
    role: UserRole.child,
    points: Points(5),
    joinedAt: DateTime(2026),
    updatedAt: DateTime(2026),
  )));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider.overrideWith((_) => MockNotificationRepository()),
      managedChildRepositoryProvider.overrideWithValue(repo),
      analyticsProvider.overrideWithValue(_NoAnalytics()),
    ],
    child: MaterialApp(theme: appLightTheme, home: const _Routing()),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.textContaining("I'm a kid"));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('child_link_code_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a good code signs this phone in as the child', (tester) async {
    await _openLinkScreen(tester, MockManagedChildRepository());

    await tester.enterText(find.byKey(const Key('link_code_field')), 'kid_uid');
    await tester.tap(find.byKey(const Key('link_code_submit')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle(); // the pop animation

    expect(find.byKey(const Key('link_code_field')), findsNothing,
        reason: 'signed in as the child, routing has left the login stack');
    expect(find.text('signed_in_home'), findsOneWidget);
  });

  testWidgets("a refused code shows the server's message", (tester) async {
    final repo = MockManagedChildRepository()
      ..refusedCodes['OLD'] = 'This code has expired. Ask a parent for a new one.';
    await _openLinkScreen(tester, repo);

    await tester.enterText(find.byKey(const Key('link_code_field')), 'OLD');
    await tester.tap(find.byKey(const Key('link_code_submit')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('This code has expired. Ask a parent for a new one.'),
        findsOneWidget);
  });
}
