import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/reward/claim_reward_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/rewards_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/rewards_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

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

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

User _testUser() => User(
      id: UserId('test_uid'),
      name: 'Test User',
      familyId: _familyId,
      role: UserRole.parent,
      points: Points(100),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

class _MockClaimRewardUseCase implements ClaimRewardUseCase {
  @override
  Future<Either<Failure, Unit>> call({required Reward reward}) async {
    return const Right(unit);
  }
}

void main() {
  testWidgets('claiming a reward celebrates with TreatRedeemed',
      (tester) async {
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(
          () => _FixedAuthNotifier(AuthState(user: _testUser()))),
      familyRewardsProvider(_familyId)
          .overrideWith((ref) => Stream.value([_testReward])),
      outstandingClaimsProvider(_familyId, UserId('test_uid'))
          .overrideWith((ref) => Future.value(<Redemption>[])),
      claimRewardUseCaseProvider
          .overrideWith((_) => _MockClaimRewardUseCase()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: appLightTheme,
          home: const RewardsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap the claim button (cost is 5 ⭐ and user has 100 stars).
    await tester.tap(find.text('5 ⭐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(celebrationQueueProvider).map((q) => q.kind),
      [const TreatRedeemed('Movie night')],
    );
  });
}
