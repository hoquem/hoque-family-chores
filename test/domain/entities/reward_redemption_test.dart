import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/reward_redemption.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

void main() {
  group('RewardRedemption', () {
    test('should create a valid redemption', () {
      final redemption = RewardRedemption(
        id: 'redemption_1',
        rewardId: 'reward_1',
        rewardName: 'Pizza Night',
        rewardIconEmoji: '🍕',
        starCost: 500,
        userId: UserId('user_1'),
        familyId: FamilyId('family_1'),
        status: RedemptionStatus.pending,
        requestedAt: DateTime.now(),
      );

      expect(redemption.isPending, true);
      expect(redemption.isApproved, false);
      expect(redemption.isRejected, false);
    });

    test('should correctly identify approved status', () {
      final redemption = RewardRedemption(
        id: 'redemption_1',
        rewardId: 'reward_1',
        rewardName: 'Pizza Night',
        rewardIconEmoji: '🍕',
        starCost: 500,
        userId: UserId('user_1'),
        familyId: FamilyId('family_1'),
        status: RedemptionStatus.approved,
        requestedAt: DateTime.now(),
        processedAt: DateTime.now(),
        processedByUserId: 'parent_1',
      );

      expect(redemption.isPending, false);
      expect(redemption.isApproved, true);
      expect(redemption.isRejected, false);
    });

    test('should correctly identify rejected status with reason', () {
      final redemption = RewardRedemption(
        id: 'redemption_1',
        rewardId: 'reward_1',
        rewardName: 'Pizza Night',
        rewardIconEmoji: '🍕',
        starCost: 500,
        userId: UserId('user_1'),
        familyId: FamilyId('family_1'),
        status: RedemptionStatus.rejected,
        requestedAt: DateTime.now(),
        processedAt: DateTime.now(),
        processedByUserId: 'parent_1',
        rejectionReason: 'Not on a school night!',
      );

      expect(redemption.isPending, false);
      expect(redemption.isApproved, false);
      expect(redemption.isRejected, true);
      expect(redemption.rejectionReason, 'Not on a school night!');
    });

    test('copyWith should update fields correctly', () {
      final original = RewardRedemption(
        id: 'redemption_1',
        rewardId: 'reward_1',
        rewardName: 'Pizza Night',
        rewardIconEmoji: '🍕',
        starCost: 500,
        userId: UserId('user_1'),
        familyId: FamilyId('family_1'),
        status: RedemptionStatus.pending,
        requestedAt: DateTime.now(),
      );

      final updated = original.copyWith(
        status: RedemptionStatus.approved,
        processedByUserId: 'parent_1',
      );

      expect(updated.status, RedemptionStatus.approved);
      expect(updated.processedByUserId, 'parent_1');
      expect(updated.id, original.id);
      expect(updated.rewardName, original.rewardName);
    });
  });
}
