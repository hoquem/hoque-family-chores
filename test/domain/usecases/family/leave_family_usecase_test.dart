// A member leaves their family: they drop off the roster and their own profile
// clears its familyId, which is what routes them back to onboarding.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/usecases/family/leave_family_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

import '../../../mocks/mock_family_repository.dart';
import '../../../mocks/mock_user_repository.dart';

FamilyEntity _family(List<UserId> members) => FamilyEntity(
      id: FamilyId('fam_1'),
      name: 'Hoque Family',
      description: '',
      creatorId: UserId('parent_uid'),
      memberIds: members,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      inviteCode: 'ABC234',
    );

User _member(UserId id) => User(
      id: id,
      name: 'Sam',
      familyId: FamilyId('fam_1'),
      role: UserRole.child,
      points: Points(12),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  test('leaving drops the roster entry and clears the profile familyId',
      () async {
    final users = MockUserRepository();
    final families = MockFamilyRepository();
    final me = UserId('child_uid');
    final parent = UserId('parent_uid');
    await families.createFamily(_family([parent, me]));
    await users.createUserProfile(_member(me));

    final result = await LeaveFamilyUseCase(families, users)(userId: me);

    expect(result.isRight(), isTrue);
    final profile = await users.getUserProfile(me);
    expect(profile!.familyId.value, isEmpty);
    expect(profile.points.value, 12, reason: 'stars stay on the account');
    final family = await families.getFamily(FamilyId('fam_1'));
    expect(family!.memberIds.map((id) => id.value), isNot(contains('child_uid')));
    expect(family.memberIds.map((id) => id.value), contains('parent_uid'));
  });

  test('leaving with no family is a business failure, not a silent no-op',
      () async {
    final users = MockUserRepository();
    final families = MockFamilyRepository();
    final me = UserId('loner_uid');
    await users.createUserProfile(
      _member(me).copyWith(familyId: FamilyId.empty),
    );

    final result = await LeaveFamilyUseCase(families, users)(userId: me);

    expect(result.isLeft(), isTrue);
  });
}
