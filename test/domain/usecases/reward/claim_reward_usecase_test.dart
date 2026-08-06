// Spending stars on a treat.
//
// The interesting behaviour is the failure split: not affording it is a
// BusinessFailure, everything else is a ServerFailure. A child who is 10 stars
// short should be told that, not shown a generic error — and the two arrive at
// the UI as different types precisely so it can tell them apart.
//
// The deduction itself is a Cloud Function's job, atomic and refusing to go
// below zero. This use case does not check the balance and must not; these
// tests pin how it reports what the server decided.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/repositories/reward_repository.dart';
import 'package:hoque_family_chores/domain/usecases/reward/claim_reward_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockRewardRepository extends Mock implements RewardRepository {}

final _familyId = FamilyId('fam1');

Reward _reward() => Reward(
      id: 'reward1',
      familyId: _familyId,
      title: 'Tennis with Dad',
      cost: Points(50),
      timeframe: RewardTimeframe.openEnded,
      createdBy: UserId('kid1'),
      createdAt: DateTime(2026, 8, 1),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
  });

  late _MockRewardRepository rewards;
  late ClaimRewardUseCase claim;

  setUp(() {
    rewards = _MockRewardRepository();
    claim = ClaimRewardUseCase(rewards);
  });

  test('claiming a treat spends the stars server-side', () async {
    when(() => rewards.claimReward(any(), any()))
        .thenAnswer((_) async => 'redemption1');

    final result = await claim(reward: _reward());

    expect(result.isRight(), isTrue);
    verify(() => rewards.claimReward(_familyId, 'reward1')).called(1);
  });

  // The split that matters. Not enough stars is a normal, expected answer —
  // the family's economy working — not a malfunction.
  test('not affording it is a BusinessFailure, not a ServerFailure', () async {
    when(() => rewards.claimReward(any(), any())).thenThrow(
        const ValidationException('Not enough stars', code: 'INSUFFICIENT'));

    final result = await claim(reward: _reward());

    final failure = result.fold((f) => f, (_) => null);
    expect(failure, isA<BusinessFailure>());
    expect(failure, isNot(isA<ServerFailure>()));
    expect(failure!.message, 'Not enough stars');
  });

  test('anything else is a ServerFailure', () async {
    when(() => rewards.claimReward(any(), any()))
        .thenThrow(const ServerException('offline', code: 'NETWORK'));

    final result = await claim(reward: _reward());

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('an unexpected error is still a failure, never a crash', () async {
    when(() => rewards.claimReward(any(), any()))
        .thenThrow(StateError('boom'));

    final result = await claim(reward: _reward());

    expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
  });
}
