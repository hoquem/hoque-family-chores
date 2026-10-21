// An expired claim is refunded on the way past (outstandingClaimsProvider).
// The stars coming back raise the balance, and StarAwardWatcher must not
// celebrate that rise as stars earned.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/star_award_watcher.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/rewards_notifier.dart';

import '../mocks/mock_reward_repository.dart';

final _familyId = FamilyId('f1');
final _userId = UserId('u1');

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._initial);
  final AuthState _initial;

  @override
  AuthState build() => _initial;

  void setUser(User? user) {
    state = state.copyWith(user: user);
  }
}

User _user(int points) => User(
      id: _userId,
      name: 'Test',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(points),
      joinedAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 20),
    );

void main() {
  test('refunding an expired claim does not celebrate stars earned', () async {
    final fake = _FakeAuthNotifier(AuthState(user: _user(45)));
    final rewards = MockRewardRepository(
      claimant: _userId,
      queryLag: Duration.zero,
    )..seedRedemption(Redemption(
        id: 'expired_1',
        familyId: _familyId,
        rewardId: 'reward_1',
        rewardTitle: 'Bike ride',
        cost: Points(15),
        claimedBy: _userId,
        claimedAt: DateTime(2026, 10, 1),
        status: RedemptionStatus.claimed,
        dueBy: DateTime(2026, 10, 2),
      ));
    final container = ProviderContainer(overrides: [
      authNotifierProvider.overrideWith(() => fake),
      rewardRepositoryProvider.overrideWith((_) => rewards),
    ]);
    addTearDown(container.dispose);
    container.read(starAwardWatcherProvider);

    final sub = container.listen(
      outstandingClaimsProvider(_familyId, _userId),
      (_, __) {},
    );
    addTearDown(sub.close);
    // Let the stream emit and the fire-and-forget refund complete.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The server's refund write reaches the profile stream.
    fake.setUser(_user(60));

    expect(
      container
          .read(celebrationQueueProvider)
          .map((q) => q.kind)
          .whereType<StarsAwarded>(),
      isEmpty,
    );
  });
}
