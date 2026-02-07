import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

Badge _makeBadge({BadgeType type = BadgeType.taskCompletion, Points? requiredPoints}) {
  return Badge(
    id: 'b1',
    name: 'Test Badge',
    description: 'desc',
    iconName: 'star',
    requiredPoints: requiredPoints ?? Points(50),
    type: type,
    familyId: FamilyId('f1'),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('Badge', () {
    test('canBeEarned when points equal', () {
      expect(_makeBadge(requiredPoints: Points(50)).canBeEarned(Points(50)), true);
    });

    test('canBeEarned when points greater', () {
      expect(_makeBadge(requiredPoints: Points(50)).canBeEarned(Points(100)), true);
    });

    test('canBeEarned false when points less', () {
      expect(_makeBadge(requiredPoints: Points(50)).canBeEarned(Points(10)), false);
    });

    test('category mapping', () {
      expect(_makeBadge(type: BadgeType.taskCompletion).category, BadgeCategory.taskMaster);
      expect(_makeBadge(type: BadgeType.streak).category, BadgeCategory.streaker);
      expect(_makeBadge(type: BadgeType.points).category, BadgeCategory.superHelper);
    });

    test('copyWith', () {
      final badge = _makeBadge();
      final copy = badge.copyWith(name: 'New Badge');
      expect(copy.name, 'New Badge');
      expect(copy.id, badge.id);
    });

    test('equality', () {
      expect(_makeBadge(), equals(_makeBadge()));
    });
  });

  group('BadgeRarity', () {
    test('displayName', () {
      expect(BadgeRarity.common.displayName, 'Common');
      expect(BadgeRarity.legendary.displayName, 'Legendary');
    });
  });

  group('BadgeCategory', () {
    test('displayName', () {
      expect(BadgeCategory.taskMaster.displayName, 'Task Master');
      expect(BadgeCategory.superHelper.displayName, 'Super Helper');
    });
  });
}
