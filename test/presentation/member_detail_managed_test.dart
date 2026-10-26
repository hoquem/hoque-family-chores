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
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/member_detail_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_managed_child_repository.dart';
import '../mocks/mock_user_repository.dart';

class _NoAnalytics extends Analytics {
  @override
  Future<void> log(
    AnalyticsEventName name, {
    required String userId,
    String? familyId,
    Map<String, Object?> params = const {},
  }) async {}
}

const _parentUid = 'mock_google_uid';
final _familyId = FamilyId('family_1');

User _child({required bool managed}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(5),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// Signs a parent into family_1 (the rewards_settle_reclaim_test pattern)
/// and opens [member]'s page.
Future<void> _pump(
  WidgetTester tester,
  User member,
  MockManagedChildRepository repo,
) async {
  final auth = MockAuthRepository();
  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => auth),
    userRepositoryProvider.overrideWith((_) => users),
    managedChildRepositoryProvider.overrideWithValue(repo),
    analyticsProvider.overrideWith((_) => _NoAnalytics()),
    taskListStreamProvider(_familyId).overrideWith((_) => Stream.value(const [])),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: appLightTheme, home: MemberDetailScreen(member: member)),
  ));

  // Sign in after the screen is watching auth, so the profile stream stays
  // alive (an unwatched AuthNotifier disposes it).
  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_parentUid));
    await users.updateUserProfile(
      profile!.copyWith(familyId: _familyId, role: UserRole.parent),
    );
  });

  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('a parent sees the managed-child actions and can make a link code',
      (tester) async {
    final repo = MockManagedChildRepository();
    await _pump(tester, _child(managed: true), repo);

    expect(find.text('Hand the phone to Amira'), findsOneWidget);
    expect(find.text('Move Amira to their own phone'), findsOneWidget);
    expect(find.text('Remove Amira'), findsOneWidget);

    await tester.tap(find.text('Move Amira to their own phone'));
    await tester.pumpAndSettle();

    expect(find.text('ABCD EFGH JKMN'), findsOneWidget);
    expect(repo.linkCodesFor.single, UserId('kid'));
  });

  testWidgets('no managed-child actions for a member with their own sign-in',
      (tester) async {
    await _pump(tester, _child(managed: false), MockManagedChildRepository());

    expect(find.text('Hand the phone to Amira'), findsNothing);
    expect(find.text('Move Amira to their own phone'), findsNothing);
    expect(find.text('Remove Amira'), findsNothing);
  });
}
