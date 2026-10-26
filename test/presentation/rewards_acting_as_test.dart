// RewardsScreen(actingAs: child) is the Treats tab of the child view on a
// parent's phone. It must show the child's balance, claim for the child, and
// offer no way to add or edit treats.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/screens/rewards_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
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

void main() {
  testWidgets('shows the child balance, claims for the child, no add button',
      (tester) async {
    final rewards = MockRewardRepository(claimant: UserId('mum'))
      ..seedReward(Reward(
        id: 'park',
        familyId: _familyId,
        title: 'Park trip',
        cost: Points(20),
        timeframe: RewardTimeframe.openEnded,
        createdBy: UserId('mum'),
        createdAt: DateTime(2026),
      ));
    addTearDown(rewards.dispose);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
        userRepositoryProvider.overrideWith((_) => MockUserRepository()),
        rewardRepositoryProvider.overrideWith((_) => rewards),
      ],
      child: MaterialApp(theme: appLightTheme, home: RewardsScreen(actingAs: _kid)),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byTooltip('Edit or delete treat'), findsNothing);

    await tester.tap(find.text('20 ⭐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final claims = await rewards.streamRedemptions(_familyId).first;
    expect(claims.single.claimedBy, UserId('kid'));
  });
}
