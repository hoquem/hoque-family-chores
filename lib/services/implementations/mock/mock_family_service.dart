import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockFamilyService implements FamilyServiceInterface {
  final Map<String, Family> _families = {};
  final Map<String, List<FamilyMember>> _familyMembers = {};

  MockFamilyService() {
    logger.i("MockFamilyService initialized with empty families list.");
  }

  @override
  Future<Family?> getFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _families[familyId];
      },
      operationName: 'getFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Family>> getFamiliesForUser({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _families.values
            .where((family) => family.memberIds.contains(userId))
            .toList();
      },
      operationName: 'getFamiliesForUser',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createFamily({required Family family}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _families[family.id] = family;
        _familyMembers[family.id] = [];
      },
      operationName: 'createFamily',
      context: {'familyId': family.id},
    );
  }

  @override
  Future<void> updateFamily({
    required String familyId,
    required Family family,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _families[familyId] = family;
      },
      operationName: 'updateFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> deleteFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _families.remove(familyId);
        _familyMembers.remove(familyId);
      },
      operationName: 'deleteFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> addUserToFamily({
    required String familyId,
    required String userId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final member = FamilyMember(
          id: userId,
          userId: userId,
          familyId: familyId,
          name: 'User $userId',
          photoUrl: '',
          role: FamilyRole.child,
          points: 0,
          joinedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _familyMembers.putIfAbsent(familyId, () => []).add(member);
      },
      operationName: 'addUserToFamily',
      context: {'familyId': familyId, 'userId': userId},
    );
  }

  @override
  Future<void> removeUserFromFamily({
    required String familyId,
    required String userId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _familyMembers[familyId]?.removeWhere((m) => m.userId == userId);
      },
      operationName: 'removeUserFromFamily',
      context: {'familyId': familyId, 'userId': userId},
    );
  }

  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        yield _familyMembers[familyId] ?? [];
      },
      streamName: 'streamFamilyMembers',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _familyMembers[familyId] ?? [];
      },
      operationName: 'getFamilyMembers',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> updateFamilyMember({
    required String familyId,
    required String memberId,
    required FamilyMember member,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final members = _familyMembers[familyId];
        if (members != null) {
          final index = members.indexWhere((m) => m.id == memberId);
          if (index != -1) {
            members[index] = member;
          }
        }
      },
      operationName: 'updateFamilyMember',
      context: {'familyId': familyId, 'memberId': memberId},
    );
  }

  @override
  Future<void> deleteFamilyMember({
    required String familyId,
    required String memberId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _familyMembers[familyId]?.removeWhere((m) => m.id == memberId);
      },
      operationName: 'deleteFamilyMember',
      context: {'familyId': familyId, 'memberId': memberId},
    );
  }
}
