// Regression test for a bug found after the splash-flash fix
// (rewards_claim_no_auth_flash_test.dart): claim a treat, settle it ("Not
// yet" or "We did it"), then claim the same treat again. The settled claim
// must disappear from the "You claimed this" card and the new claim must be
// the only outstanding one -- settling the new claim must not hit "That one
// is already settled." (settle_redemption_usecase.dart:37), which can only
// happen if a stale, already-settled `Redemption` is still being acted on.
//
// `outstandingClaimsProvider` (rewards_notifier.dart) is a one-shot Future
// provider backed by a Firestore `.get()`, not a live stream. It only
// reflects a claim/settle once something calls
// `ref.invalidate(outstandingClaimsProvider(...))`. Before the splash-flash
// fix, every claim/settle also invalidated `authNotifierProvider`, which tore
// down and rebuilt the whole MainScreen subtree -- disposing and recreating
// `outstandingClaimsProvider` from scratch regardless of whether the
// explicit invalidate below was correct. That incidental full teardown is
// gone now, so this provider's own invalidation has to be correct on its
// own, and this test is here to prove it is (or catch it if it isn't).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_reward_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _familyId = FamilyId('family_1');

final _testReward = Reward(
  id: 'reward_1',
  familyId: _familyId,
  title: 'Movie night',
  cost: Points(5),
  timeframe: RewardTimeframe.openEnded,
  createdBy: UserId('parent_1'),
  createdAt: DateTime(2026, 7, 20),
);

/// Signs a parent into `family_1` with [points] to spend and a real
/// [MockRewardRepository] wired through the production claim/settle use
/// cases and `outstandingClaimsProvider` -- nothing reward-related is
/// overridden except the repository itself, so the app's actual invalidate
/// logic runs unmodified.
Future<ProviderContainer> _pumpSignedIn(
  WidgetTester tester,
  MockAuthRepository auth,
  MockUserRepository users,
  MockRewardRepository rewards, {
  required int points,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider.overrideWith(
        (_) => MockNotificationRepository(),
      ),
      rewardRepositoryProvider.overrideWith((_) => rewards),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: const FamilyGate()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(
      profile!.copyWith(familyId: _familyId, points: Points(points)),
    );
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));

  await tester.tap(find.text('Treats').last);
  await tester.pump(const Duration(milliseconds: 300));

  return container;
}

/// The reward's own tile and every outstanding-claim row both show the
/// reward's title in a ListTile, so this count is "1 (the reward tile) + the
/// number of outstanding claims shown".
Finder _movieNightTiles() => find.widgetWithText(ListTile, 'Movie night');

void main() {
  testWidgets(
    'settling a claim ("Not yet") then re-claiming leaves exactly the new '
    'claim outstanding, and it settles cleanly',
    (tester) async {
      final auth = MockAuthRepository();
      final users = MockUserRepository();
      final rewards = MockRewardRepository(claimant: UserId(_uid))
        ..seedReward(_testReward);
      addTearDown(rewards.dispose);
      final container = await _pumpSignedIn(
        tester,
        auth,
        users,
        rewards,
        points: 50,
      );
      addTearDown(container.dispose);

      // Claim.
      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('You claimed this'), findsOneWidget);
      expect(_movieNightTiles(), findsNWidgets(2));

      // Refund ("Not yet").
      await tester.tap(find.text('Not yet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('You claimed this'),
        findsNothing,
        reason: 'the refunded claim must not still show as owed',
      );
      expect(_movieNightTiles(), findsNWidgets(1));

      // Claim the same treat again.
      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('You claimed this'),
        findsOneWidget,
        reason: 'the new claim must show as owed',
      );
      expect(
        _movieNightTiles(),
        findsNWidgets(2),
        reason:
            'exactly one outstanding claim (the new one) -- the settled one '
            'must not still be showing alongside it',
      );
      expect(find.text('Not yet'), findsOneWidget);
      expect(find.text('We did it'), findsOneWidget);

      // Settling the new claim must succeed, not hit "already settled".
      await tester.tap(find.text('Not yet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Stars refunded'), findsOneWidget);
      expect(find.textContaining('already settled'), findsNothing);
    },
  );

  testWidgets(
    'settling a claim ("We did it") then re-claiming leaves exactly the new '
    'claim outstanding, and it settles cleanly',
    (tester) async {
      final auth = MockAuthRepository();
      final users = MockUserRepository();
      final rewards = MockRewardRepository(claimant: UserId(_uid))
        ..seedReward(_testReward);
      addTearDown(rewards.dispose);
      final container = await _pumpSignedIn(
        tester,
        auth,
        users,
        rewards,
        points: 50,
      );
      addTearDown(container.dispose);

      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('We did it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('You claimed this'), findsNothing);
      expect(_movieNightTiles(), findsNWidgets(1));

      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(_movieNightTiles(), findsNWidgets(2));

      await tester.tap(find.text('We did it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Nice — enjoy it! 🎉'), findsOneWidget);
      expect(find.textContaining('already settled'), findsNothing);
    },
  );
}
