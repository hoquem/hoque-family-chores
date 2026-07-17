// The deadline and the refund are the whole feature, and both are pure logic.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

// Wednesday 15 July 2026, 18:30.
final _now = DateTime(2026, 7, 15, 18, 30);
final _me = UserId('kid1');
final _familyId = FamilyId('fam1');

Redemption _claim({DateTime? dueBy, RedemptionStatus? status}) => Redemption(
      id: 'r1',
      familyId: _familyId,
      rewardId: 'rw1',
      rewardTitle: 'Walk in the park',
      cost: Points(200),
      claimedBy: _me,
      claimedAt: _now,
      status: status ?? RedemptionStatus.claimed,
      dueBy: dueBy,
    );

void main() {
  group('RewardTimeframe.dueFrom', () {
    test('open-ended never expires', () {
      expect(RewardTimeframe.openEnded.dueFrom(_now), isNull);
    });

    test('this week runs to the end of Sunday', () {
      // Wednesday the 15th → Sunday the 19th ends as Monday the 20th begins.
      expect(RewardTimeframe.thisWeek.dueFrom(_now), DateTime(2026, 7, 20));
    });

    test('this week from a Sunday still gives that day', () {
      // Sunday 19 July. The naive "+7 days" would say next Sunday; the
      // promise was *this* week.
      final sunday = DateTime(2026, 7, 19, 9);
      expect(RewardTimeframe.thisWeek.dueFrom(sunday), DateTime(2026, 7, 20));
    });

    test('this month runs to the end of the month', () {
      expect(RewardTimeframe.thisMonth.dueFrom(_now), DateTime(2026, 8, 1));
    });

    test('this month rolls the year over in December', () {
      final december = DateTime(2026, 12, 3);
      expect(RewardTimeframe.thisMonth.dueFrom(december), DateTime(2027, 1, 1));
    });
  });

  group('Redemption.isExpired', () {
    test('an open-ended claim never expires', () {
      expect(_claim(dueBy: null).isExpired(_now.add(const Duration(days: 900))),
          isFalse,
          reason: 'no deadline means no automatic refund — but the claimant '
              'can still ask for one');
    });

    test('a claim before its deadline is not expired', () {
      expect(_claim(dueBy: DateTime(2026, 7, 20)).isExpired(_now), isFalse);
    });

    test('a claim at its deadline is expired', () {
      // The deadline is the first instant that is too late.
      expect(
        _claim(dueBy: DateTime(2026, 7, 20)).isExpired(DateTime(2026, 7, 20)),
        isTrue,
      );
    });

    test('a settled claim never expires again', () {
      // Otherwise a fulfilled claim would refund itself the moment its
      // deadline passed, and the stars would come back after the outing.
      expect(
        _claim(dueBy: DateTime(2026, 7, 20), status: RedemptionStatus.fulfilled)
            .isExpired(DateTime(2027, 1, 1)),
        isFalse,
      );
      expect(
        _claim(dueBy: DateTime(2026, 7, 20), status: RedemptionStatus.refunded)
            .isExpired(DateTime(2027, 1, 1)),
        isFalse,
      );
    });
  });

  group('Redemption.settle', () {
    test('keeps the cost snapshot so history cannot be rewritten', () {
      final settled = _claim().settle(RedemptionStatus.fulfilled, _now);
      expect(settled.cost, Points(200));
      expect(settled.rewardTitle, 'Walk in the park');
      expect(settled.settledAt, _now);
      expect(settled.isOutstanding, isFalse);
    });
  });
}
