import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

Reward _makeReward({Points? pointsCost}) {
  return Reward(
    id: 'r1',
    name: 'Screen Time',
    description: '30 min extra screen time',
    pointsCost: pointsCost ?? Points(50),
    iconName: 'tv',
    type: RewardType.privilege,
    familyId: FamilyId('f1'),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('Reward', () {
    test('canBeAfforded', () {
      final reward = _makeReward(pointsCost: Points(50));
      expect(reward.canBeAfforded(Points(100)), true);
      expect(reward.canBeAfforded(Points(50)), true);
      expect(reward.canBeAfforded(Points(10)), false);
    });

    test('costAsInt', () {
      expect(_makeReward(pointsCost: Points(42)).costAsInt, 42);
    });

    test('isAvailable', () {
      expect(_makeReward().isAvailable, true);
    });

    test('copyWith', () {
      final r = _makeReward();
      final copy = r.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.id, r.id);
    });

    test('equality', () {
      expect(_makeReward(), equals(_makeReward()));
    });
  });

  group('RewardType', () {
    test('displayName', () {
      expect(RewardType.digital.displayName, 'Digital');
      expect(RewardType.physical.displayName, 'Physical');
      expect(RewardType.privilege.displayName, 'Privilege');
    });
  });

  group('RewardRarity', () {
    test('displayName', () {
      expect(RewardRarity.common.displayName, 'Common');
      expect(RewardRarity.legendary.displayName, 'Legendary');
    });
  });
}
