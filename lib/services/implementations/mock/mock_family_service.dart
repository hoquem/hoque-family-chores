import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';

class MockFamilyService implements FamilyServiceInterface {
  final Map<String, Family> _families = {};
  final Map<String, List<FamilyMember>> _familyMembers = {};

  MockFamilyService() {
    logger.i("MockFamilyService initialized with mock data.");
    _initializeMockData();
  }

  void _initializeMockData() {
    logger.i("MockFamilyService: Starting mock data initialization");
    
    // Initialize family
    final familyData = MockData.family;
    logger.d("MockFamilyService: Family data: $familyData");
    
    final memberIds = MockData.userProfiles.map((user) => user['id'] as String).toList();
    logger.d("MockFamilyService: Member IDs: $memberIds");
    
    final family = Family(
      id: familyData['id'],
      name: familyData['name'],
      description: familyData['description'],
      creatorId: familyData['creatorUserId'],
      memberIds: memberIds,
      createdAt: DateTime.parse(familyData['createdAt']),
      updatedAt: DateTime.parse(familyData['createdAt']), // Using createdAt as updatedAt for mock
      photoUrl: familyData['photoUrl'],
    );
    _families[family.id] = family;
    logger.i("MockFamilyService: Created family: ${family.name} with ID: ${family.id}");

    // Initialize family members
    final members = <FamilyMember>[];
    logger.d("MockFamilyService: Processing ${MockData.userProfiles.length} user profiles");
    
    for (final userData in MockData.userProfiles) {
      logger.d("MockFamilyService: Processing user: ${userData['displayName']} (${userData['id']})");
      
      final member = FamilyMember(
        id: userData['id'],
        userId: userData['id'],
        familyId: MockData.familyId,
        name: userData['displayName'],
        photoUrl: userData['photoUrl'],
        role: FamilyRole.values.firstWhere(
          (role) => role.name == userData['role'],
        ),
        points: userData['points'],
        joinedAt: DateTime.parse(userData['createdAt']),
        updatedAt: DateTime.parse(userData['lastActive']),
      );
      members.add(member);
      logger.d("MockFamilyService: Created member: ${member.name} with ${member.points} points");
    }

    _familyMembers[MockData.familyId] = members;
    logger.i("MockFamilyService: Initialized with ${members.length} family members for family ${MockData.familyId}");
    logger.d("MockFamilyService: Available families: ${_families.keys.toList()}");
  }

  @override
  Future<Family?> getFamily({required String familyId}) async {
    logger.d("MockFamilyService: getFamily called with familyId: $familyId");
    logger.d("MockFamilyService: Available families: ${_families.keys.toList()}");
    
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final family = _families[familyId];
        logger.d("MockFamilyService: getFamily returning: ${family?.name ?? 'null'}");
        return family;
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
