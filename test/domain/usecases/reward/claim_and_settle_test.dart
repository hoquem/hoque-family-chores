// Where the stars actually move. The ordering in these flows is the whole
// correctness argument, so most of these tests assert *sequence*, not outcome.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/repositories/reward_repository.dart';
import 'package:hoque_family_chores/domain/repositories/user_repository.dart';
import 'package:hoque_family_chores/domain/usecases/reward/claim_reward_usecase.dart';
import 'package:hoque_family_chores/domain/usecases/reward/settle_redemption_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:mocktail/mocktail.dart';

class _MockRewards extends Mock implements RewardRepository {}

class _MockUsers extends Mock implements UserRepository {}

final _now = DateTime(2026, 7, 15, 18, 30);
final _me = UserId('kid1');
final _sibling = UserId('kid2');
final _familyId = FamilyId('fam1');

final _reward = Reward(
  id: 'rw1',
  familyId: _familyId,
  title: 'Walk in the park',
  cost: Points(200),
  timeframe: RewardTimeframe.thisWeek,
  createdBy: _me,
  createdAt: _now,
);

Redemption _claim({
  RedemptionStatus status = RedemptionStatus.claimed,
  UserId? by,
}) =>
    Redemption(
      id: 'rd1',
      familyId: _familyId,
      rewardId: 'rw1',
      rewardTitle: 'Walk in the park',
      cost: Points(200),
      claimedBy: by ?? _me,
      claimedAt: _now,
      status: status,
      dueBy: DateTime(2026, 7, 20),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(UserId('fallback'));
    registerFallbackValue(FamilyId('fallback'));
    registerFallbackValue(Points(0));
    registerFallbackValue(RedemptionStatus.claimed);
    registerFallbackValue(_claim());
    registerFallbackValue(DateTime(2026));
  });

  late _MockRewards rewards;
  late _MockUsers users;

  setUp(() {
    rewards = _MockRewards();
    users = _MockUsers();
    when(() => users.subtractPoints(any(), any())).thenAnswer((_) async {});
    when(() => users.addPoints(any(), any())).thenAnswer((_) async {});
    when(() => rewards.createRedemption(any()))
        .thenAnswer((i) async => i.positionalArguments.first as Redemption);
    when(() => rewards.settleRedemption(any(), any(), any(), any()))
        .thenAnswer((_) async {});
  });

  group('claiming', () {
    test('spends the stars and records the promise', () async {
      final result = await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      expect(result.isRight(), isTrue);
      verify(() => users.subtractPoints(_me, Points(200))).called(1);
    });

    test('takes the stars BEFORE recording the claim', () async {
      // The reverse order would record a promise the claimant never paid for:
      // the family would owe an outing bought with stars still in the bank.
      await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      verifyInOrder([
        () => users.subtractPoints(_me, Points(200)),
        () => rewards.createRedemption(any()),
      ]);
    });

    test('not enough stars: nothing is recorded', () async {
      when(() => users.subtractPoints(any(), any())).thenThrow(
        ValidationException('nope', code: 'INSUFFICIENT_POINTS'),
      );

      final result = await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<BusinessFailure>()), (_) => fail('!'));
      verifyNever(() => rewards.createRedemption(any()));
    });

    test('if recording fails, the stars come back', () async {
      // Otherwise they vanish: taken, but no claim exists to show for them.
      // Silently losing a child's stars is the worst outcome this flow has.
      when(() => rewards.createRedemption(any()))
          .thenThrow(ServerException('offline', code: 'X'));

      final result = await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      expect(result.isLeft(), isTrue);
      verify(() => users.addPoints(_me, Points(200))).called(1);
    });

    test('the creator can claim their own reward', () async {
      // "Bike ride with Dad", proposed and claimed by the same child, is the
      // feature working. The stars were earned on chores someone else signed
      // off.
      expect(_reward.createdBy, _me);

      final result = await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      expect(result.isRight(), isTrue);
    });

    test('the deadline comes from the reward, not the claim', () async {
      final captured = <Redemption>[];
      when(() => rewards.createRedemption(any())).thenAnswer((i) async {
        final r = i.positionalArguments.first as Redemption;
        captured.add(r);
        return r;
      });

      await ClaimRewardUseCase(rewards, users)(
        reward: _reward,
        claimedBy: _me,
        now: _now,
      );

      // thisWeek from Wednesday the 15th → end of Sunday the 19th.
      expect(captured.single.dueBy, DateTime(2026, 7, 20));
      expect(captured.single.cost, Points(200));
      expect(captured.single.rewardTitle, 'Walk in the park');
    });
  });

  group('settling', () {
    test('it happened: stars stay spent', () async {
      final result = await SettleRedemptionUseCase(rewards, users)(
        redemption: _claim(),
        actor: _me,
        happened: true,
        now: _now,
      );

      expect(result.isRight(), isTrue);
      verify(() => rewards.settleRedemption(
          _familyId, 'rd1', RedemptionStatus.fulfilled, _now)).called(1);
      verifyNever(() => users.addPoints(any(), any()));
    });

    test('it did not happen: the stars go back', () async {
      final result = await SettleRedemptionUseCase(rewards, users)(
        redemption: _claim(),
        actor: _me,
        happened: false,
        now: _now,
      );

      expect(result.isRight(), isTrue);
      verify(() => users.addPoints(_me, Points(200))).called(1);
    });

    test('records the outcome BEFORE refunding', () async {
      // If the refund landed and this then failed, the claim would still read
      // as outstanding and could be refunded again — stars from nothing.
      await SettleRedemptionUseCase(rewards, users)(
        redemption: _claim(),
        actor: _me,
        happened: false,
        now: _now,
      );

      verifyInOrder([
        () => rewards.settleRedemption(any(), any(), any(), any()),
        () => users.addPoints(_me, Points(200)),
      ]);
    });

    test('only the claimant may judge — not even a parent', () async {
      // A parent insisting the park trip counted would be the app taking the
      // family's side against the child.
      final result = await SettleRedemptionUseCase(rewards, users)(
        redemption: _claim(by: _me),
        actor: _sibling,
        happened: true,
        now: _now,
      );

      expect(result.isLeft(), isTrue);
      result.fold((f) => expect(f, isA<PermissionFailure>()), (_) => fail('!'));
      verifyNever(() => rewards.settleRedemption(any(), any(), any(), any()));
    });

    test('an already-settled claim cannot be settled again', () async {
      // Double-refunding is the exploit: claim, refund, refund again.
      final result = await SettleRedemptionUseCase(rewards, users)(
        redemption: _claim(status: RedemptionStatus.refunded),
        actor: _me,
        happened: false,
        now: _now,
      );

      expect(result.isLeft(), isTrue);
      verifyNever(() => users.addPoints(any(), any()));
    });
  });
}
