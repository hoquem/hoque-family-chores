import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/repositories/managed_child_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/member_profile_provider.dart';
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

/// createLinkCode waits on [gate], standing in for the 3-7 s callable.
class _SlowLinkRepository extends MockManagedChildRepository {
  final gate = Completer<void>();
  int createCalls = 0;

  @override
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId) async {
    createCalls++;
    await gate.future;
    return super.createLinkCode(familyId, childId);
  }
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
  MockManagedChildRepository repo, {
  Stream<User?>? live,
}) async {
  final auth = MockAuthRepository();
  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => auth),
    userRepositoryProvider.overrideWith((_) => users),
    managedChildRepositoryProvider.overrideWithValue(repo),
    analyticsProvider.overrideWith((_) => _NoAnalytics()),
    taskListStreamProvider(_familyId).overrideWith((_) => Stream.value(const [])),
    memberProfileProvider(member.id)
        .overrideWith((_) => live ?? Stream.value(member)),
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

  testWidgets('the page follows the live profile: stars update, actions go once linked',
      (tester) async {
    final live = StreamController<User?>();
    addTearDown(live.close);
    await _pump(tester, _child(managed: true), MockManagedChildRepository(),
        live: live.stream);

    expect(find.text('5 ⭐'), findsOneWidget);
    expect(find.text('Child · No phone'), findsOneWidget);
    expect(find.text('Remove Amira'), findsOneWidget);

    live.add(_child(managed: true).copyWith(points: Points(9)));
    await tester.pumpAndSettle();
    expect(find.text('9 ⭐'), findsOneWidget);

    live.add(_child(managed: false).copyWith(points: Points(9)));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);
    expect(find.text('Hand the phone to Amira'), findsNothing);
    expect(find.text('Move Amira to their own phone'), findsNothing);
    expect(find.text('Remove Amira'), findsNothing);
  });

  testWidgets('shows progress while the link code is created and ignores a second tap',
      (tester) async {
    final repo = _SlowLinkRepository();
    await _pump(tester, _child(managed: true), repo);

    await tester.tap(find.text('Move Amira to their own phone'));
    await tester.pump();

    expect(find.byKey(const Key('link_code_progress')), findsOneWidget);
    expect(repo.createCalls, 1);

    // The button is disabled: tapping it again must not start a second request.
    await tester.tap(find.text('Move Amira to their own phone'), warnIfMissed: false);
    await tester.pump();
    expect(repo.createCalls, 1);

    repo.gate.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('link_code_progress')), findsNothing);
    expect(find.text('ABCD EFGH JKMN'), findsOneWidget);
    expect(repo.createCalls, 1);
  });

  testWidgets('a profile stream error is shown on the page', (tester) async {
    final live = StreamController<User?>();
    addTearDown(live.close);
    await _pump(tester, _child(managed: true), MockManagedChildRepository(),
        live: live.stream);

    live.addError(Exception('permission-denied'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text("Couldn't update Amira's details"), findsOneWidget);
  });

  testWidgets('a deleted profile shows that the member is gone', (tester) async {
    final live = StreamController<User?>();
    addTearDown(live.close);
    await _pump(tester, _child(managed: true), MockManagedChildRepository(),
        live: live.stream);

    live.add(null);
    await tester.pumpAndSettle();

    expect(find.text('Amira is no longer in this family'), findsOneWidget);
    expect(find.text('Remove Amira'), findsNothing);
  });

  testWidgets('no dialog if the child linked while the code was being created',
      (tester) async {
    final live = StreamController<User?>();
    addTearDown(live.close);
    final repo = _SlowLinkRepository();
    await _pump(tester, _child(managed: true), repo, live: live.stream);

    await tester.tap(find.text('Move Amira to their own phone'));
    await tester.pump();
    live.add(_child(managed: false));
    await tester.pump();
    repo.gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('ABCD EFGH JKMN'), findsNothing);
  });
}
