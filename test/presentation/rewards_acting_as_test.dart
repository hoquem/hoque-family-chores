// RewardsScreen(actingAs: child) is the Treats tab of the child view on a
// parent's phone. It must show the child's balance, claim for the child, and
// offer no way to add or edit treats.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/star_award_watcher.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/rewards_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/rewards_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_reward_repository.dart';
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

const _parentUid = 'mock_google_uid';

final _park = Reward(
  id: 'park',
  familyId: _familyId,
  title: 'Park trip',
  cost: Points(20),
  timeframe: RewardTimeframe.openEnded,
  createdBy: UserId('mum'),
  createdAt: DateTime(2026),
);

/// Records the `forMemberId` of every settle, then behaves as the mock.
class _RecordingRewards extends MockRewardRepository {
  _RecordingRewards({required super.claimant});

  final settledFor = <UserId?>[];

  @override
  Future<void> settleRedemption(
    FamilyId familyId,
    String redemptionId, {
    required bool happened,
    UserId? forMemberId,
  }) {
    settledFor.add(forMemberId);
    return super.settleRedemption(
      familyId,
      redemptionId,
      happened: happened,
      forMemberId: forMemberId,
    );
  }
}

/// Records the refunds the treat flow announces to the star watcher.
class _RecordingWatcher extends StarAwardWatcher {
  final expected = <int>[];

  @override
  void expectRefund(Points amount) {
    expected.add(amount.value);
    super.expectRefund(amount);
  }
}

/// A container with a parent (holding 99 stars) signed in to family_1.
Future<ProviderContainer> _signedInParent(
  _RecordingRewards rewards,
  _RecordingWatcher watcher,
) async {
  final users = MockUserRepository();
  final container = ProviderContainer(overrides: [
    authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
    userRepositoryProvider.overrideWith((_) => users),
    familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
    taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
    notificationRepositoryProvider
        .overrideWith((_) => MockNotificationRepository()),
    rewardRepositoryProvider.overrideWith((_) => rewards),
    starAwardWatcherProvider.overrideWith(() => watcher),
  ]);
  // Held open: the auth notifier is auto-disposed without a listener.
  container.listen(authNotifierProvider, (_, __) {});
  await container.read(authNotifierProvider.notifier).signInWithGoogle();
  final profile = await users.getUserProfile(UserId(_parentUid));
  await users.updateUserProfile(profile!.copyWith(
    familyId: _familyId,
    role: UserRole.parent,
    points: Points(99),
  ));
  await Future<void>.delayed(const Duration(milliseconds: 100));
  expect(container.read(authNotifierProvider).user?.id, UserId(_parentUid));
  return container;
}

Redemption _expiredClaim(UserId claimedBy) => Redemption(
      id: 'old',
      familyId: _familyId,
      rewardId: 'park',
      rewardTitle: 'Park trip',
      cost: Points(20),
      claimedBy: claimedBy,
      claimedAt: DateTime(2026),
      status: RedemptionStatus.claimed,
      dueBy: DateTime(2026, 1, 2),
    );

void main() {
  testWidgets('shows the child balance, claims for the child, no add button',
      (tester) async {
    final rewards = _RecordingRewards(claimant: UserId(_parentUid))
      ..seedReward(_park);
    addTearDown(rewards.dispose);
    final watcher = _RecordingWatcher();
    final container = await tester.runAsync(
      () => _signedInParent(rewards, watcher),
    );
    addTearDown(container!.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: RewardsScreen(actingAs: _kid),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('30 ⭐'), findsOneWidget, reason: "the child's balance");
    expect(find.text('99 ⭐'), findsNothing, reason: "not the parent's");
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Edit or delete treat'), findsNothing);

    await tester.tap(find.text('20 ⭐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final claims = await rewards.streamRedemptions(_familyId).first;
    expect(claims.single.claimedBy, UserId('kid'));

    // "Not yet" is settled for the child, and is not announced as a refund to
    // the parent's star watcher (the parent's balance does not move).
    await tester.tap(find.text('Not yet'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(rewards.settledFor, [UserId('kid')]);
    expect(watcher.expected, isEmpty);
  });

  group('outstandingClaims lazy refund', () {
    test("for a child's expired claim settles on behalf, unannounced",
        () async {
      final rewards = _RecordingRewards(claimant: UserId(_parentUid))
        ..seedRedemption(_expiredClaim(UserId('kid')));
      addTearDown(rewards.dispose);
      final watcher = _RecordingWatcher();
      final container = await _signedInParent(rewards, watcher);
      addTearDown(container.dispose);

      final sub = container.listen(
        outstandingClaimsProvider(_familyId, UserId('kid')),
        (_, __) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(rewards.settledFor, [UserId('kid')]);
      expect(watcher.expected, isEmpty);
    });

    test("for the signed-in user's expired claim settles as self, announced",
        () async {
      final rewards = _RecordingRewards(claimant: UserId(_parentUid))
        ..seedRedemption(_expiredClaim(UserId(_parentUid)));
      addTearDown(rewards.dispose);
      final watcher = _RecordingWatcher();
      final container = await _signedInParent(rewards, watcher);
      addTearDown(container.dispose);

      final sub = container.listen(
        outstandingClaimsProvider(_familyId, UserId(_parentUid)),
        (_, __) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(rewards.settledFor, [null]);
      expect(watcher.expected, [20]);
    });
  });
}
