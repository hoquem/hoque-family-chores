// Closing a claim: it happened, or the stars go back.
//
// These exist because `firestore.rules` points at them. The redemptions rules
// are deliberately permissive within a family, and the comment there explains
// why:
//
//   "you may only settle your own claim" and "a settled claim cannot be
//   settled twice" both depend on comparing a write against existing state
//   and on who claimed it. Those live in SettleRedemptionUseCase, with tests.
//
// There were no tests. The rules were citing a safety net that did not exist,
// and this use case sat at 0/12 covered lines. Both invariants are pinned
// below, and both are mutation-checked.
//
// The Cloud Function re-reads status inside its transaction and is the real
// guard; these checks are the friendly early exit in front of it. That makes
// them a UX contract rather than a security boundary — but the rules file
// claimed them, so they are now enforced somewhere.
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/repositories/reward_repository.dart';
import 'package:hoque_family_chores/domain/usecases/reward/settle_redemption_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockRewardRepository extends Mock implements RewardRepository {}

final _me = UserId('kid1');
final _sibling = UserId('kid2');
final _familyId = FamilyId('fam1');

Redemption _claim({
  UserId? claimedBy,
  RedemptionStatus status = RedemptionStatus.claimed,
}) =>
    Redemption(
      id: 'r1',
      familyId: _familyId,
      rewardId: 'reward1',
      rewardTitle: 'Tennis with Dad',
      cost: Points(50),
      claimedBy: claimedBy ?? _me,
      claimedAt: DateTime(2026, 8, 1),
      status: status,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FamilyId('fallback'));
  });

  late _MockRewardRepository rewards;
  late SettleRedemptionUseCase settle;

  setUp(() {
    rewards = _MockRewardRepository();
    settle = SettleRedemptionUseCase(rewards);
    when(() => rewards.settleRedemption(any(), any(),
        happened: any(named: 'happened'))).thenAnswer((_) async {});
  });

  group('the claimant is the judge', () {
    test('the person who claimed it can say it happened', () async {
      final result = await settle(
          redemption: _claim(claimedBy: _me), actor: _me, happened: true);

      expect(result.isRight(), isTrue);
      verify(() => rewards.settleRedemption(_familyId, 'r1', happened: true))
          .called(1);
    });

    test('saying it did not happen sends the stars back', () async {
      final result = await settle(
          redemption: _claim(claimedBy: _me), actor: _me, happened: false);

      expect(result.isRight(), isTrue);
      verify(() => rewards.settleRedemption(_familyId, 'r1', happened: false))
          .called(1);
    });

    // The invariant firestore.rules delegates here. A parent insisting the park
    // trip counted would be the app taking the family's side against the child.
    test('nobody else can settle it, not even a parent', () async {
      final result = await settle(
          redemption: _claim(claimedBy: _sibling), actor: _me, happened: true);

      expect(result.fold((f) => f, (_) => null), isA<PermissionFailure>());
      verifyNever(() => rewards.settleRedemption(any(), any(),
          happened: any(named: 'happened')));
    });
  });

  group('a claim settles once', () {
    // The other invariant firestore.rules delegates here. Settling twice would
    // either refund the stars again or take back an outing that happened.
    test('an already-fulfilled claim cannot be settled again', () async {
      final result = await settle(
        redemption: _claim(status: RedemptionStatus.fulfilled),
        actor: _me,
        happened: true,
      );

      expect(result.fold((f) => f, (_) => null), isA<BusinessFailure>());
      verifyNever(() => rewards.settleRedemption(any(), any(),
          happened: any(named: 'happened')));
    });

    test('a refunded claim cannot be settled again', () async {
      final result = await settle(
        redemption: _claim(status: RedemptionStatus.refunded),
        actor: _me,
        happened: false,
      );

      expect(result.fold((f) => f, (_) => null), isA<BusinessFailure>());
      verifyNever(() => rewards.settleRedemption(any(), any(),
          happened: any(named: 'happened')));
    });
  });

  group('when the repository fails', () {
    test('a DataException becomes a ServerFailure, not a crash', () async {
      when(() => rewards.settleRedemption(any(), any(),
              happened: any(named: 'happened')))
          .thenThrow(const ServerException('offline', code: 'NETWORK'));

      final result = await settle(
          redemption: _claim(), actor: _me, happened: true);

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
    });
  });
}
