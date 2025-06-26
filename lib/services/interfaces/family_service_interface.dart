import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/models/family_member.dart';

abstract class FamilyServiceInterface {
  Future<Family?> getFamily({required String familyId});
  Future<List<Family>> getFamiliesForUser({required String userId});
  Future<void> createFamily({required Family family});
  Future<void> updateFamily({required String familyId, required Family family});
  Future<void> deleteFamily({required String familyId});
  Future<void> addUserToFamily({
    required String familyId,
    required String userId,
  });
  Future<void> removeUserFromFamily({
    required String familyId,
    required String userId,
  });
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId});
  Future<List<FamilyMember>> getFamilyMembers({required String familyId});
  Future<void> updateFamilyMember({
    required String familyId,
    required String memberId,
    required FamilyMember member,
  });
  Future<void> deleteFamilyMember({
    required String familyId,
    required String memberId,
  });
}
