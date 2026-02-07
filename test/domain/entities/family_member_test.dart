import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/family_member.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

void main() {
  group('FamilyMember', () {
    test('creates with defaults', () {
      final member = FamilyMember(
        userId: UserId('u1'),
        familyId: FamilyId('f1'),
        name: 'Test',
        role: FamilyRole.parent,
        joinedAt: DateTime(2024, 1, 1),
      );
      expect(member.points, Points.zero);
      expect(member.isActive, true);
    });

    test('id alias returns userId', () {
      final member = FamilyMember(
        userId: UserId('u1'),
        familyId: FamilyId('f1'),
        name: 'Test',
        role: FamilyRole.child,
        joinedAt: DateTime(2024, 1, 1),
      );
      expect(member.id, member.userId);
    });

    test('equality', () {
      final a = FamilyMember(
        userId: UserId('u1'),
        familyId: FamilyId('f1'),
        name: 'Test',
        role: FamilyRole.parent,
        joinedAt: DateTime(2024, 1, 1),
      );
      final b = FamilyMember(
        userId: UserId('u1'),
        familyId: FamilyId('f1'),
        name: 'Test',
        role: FamilyRole.parent,
        joinedAt: DateTime(2024, 1, 1),
      );
      expect(a, equals(b));
    });
  });
}
