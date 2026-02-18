import 'dart:async';
import 'package:hoque_family_chores/domain/repositories/family_repository.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/core/error/exceptions.dart';

/// Mock implementation of FamilyRepository for testing
class MockFamilyRepository implements FamilyRepository {
  final Map<String, FamilyEntity> _families = {};
  final Map<String, List<User>> _familyMembers = {};

  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return _families[familyId.value];
  }

  @override
  Future<List<FamilyEntity>> getFamiliesForUser(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _families.values
        .where((family) => family.memberIds.contains(userId))
        .toList();
  }

  @override
  Future<void> createFamily(FamilyEntity family) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _families[family.id.value] = family;
  }

  @override
  Future<void> updateFamily(FamilyEntity family) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!_families.containsKey(family.id.value)) {
      throw ServerException('Family not found', code: 'FAMILY_NOT_FOUND');
    }
    _families[family.id.value] = family;
  }

  @override
  Future<void> deleteFamily(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _families.remove(familyId.value);
    _familyMembers.remove(familyId.value);
  }

  @override
  Future<void> addUserToFamily(FamilyId familyId, UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final family = _families[familyId.value];
    if (family == null) {
      throw ServerException('Family not found', code: 'FAMILY_NOT_FOUND');
    }
    
    final updatedFamily = family.addMember(userId);
    _families[familyId.value] = updatedFamily;
  }

  @override
  Future<void> removeUserFromFamily(FamilyId familyId, UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final family = _families[familyId.value];
    if (family == null) {
      throw ServerException('Family not found', code: 'FAMILY_NOT_FOUND');
    }
    
    final updatedFamily = family.removeMember(userId);
    _families[familyId.value] = updatedFamily;
  }

  @override
  Stream<List<User>> streamFamilyMembers(FamilyId familyId) {
    return Stream.fromFuture(getFamilyMembers(familyId));
  }

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _familyMembers[familyId.value] ?? [];
  }

  @override
  Future<void> updateFamilyMember(FamilyId familyId, UserId memberId, User member) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final members = _familyMembers[familyId.value] ?? [];
    final index = members.indexWhere((m) => m.id == memberId);
    if (index == -1) {
      throw ServerException('Family member not found', code: 'MEMBER_NOT_FOUND');
    }
    members[index] = member;
    _familyMembers[familyId.value] = members;
  }

  @override
  Future<void> deleteFamilyMember(FamilyId familyId, UserId memberId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final members = _familyMembers[familyId.value] ?? [];
    members.removeWhere((m) => m.id == memberId);
    _familyMembers[familyId.value] = members;
  }

  /// Helper method to add test data
  void addTestFamily(FamilyEntity family) {
    _families[family.id.value] = family;
  }

  /// Helper method to add test family members
  void addTestFamilyMembers(FamilyId familyId, List<User> members) {
    _familyMembers[familyId.value] = members;
  }
} 