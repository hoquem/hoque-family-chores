import 'dart:async';
import '../entities/family.dart';
import '../entities/user.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../../core/error/failures.dart';

/// Repository interface for family-related operations
abstract class FamilyRepository {
  /// Get a family by its ID
  Future<FamilyEntity?> getFamily(FamilyId familyId);

  /// Get all families for a specific user
  Future<List<FamilyEntity>> getFamiliesForUser(UserId userId);

  /// Create a new family
  Future<void> createFamily(FamilyEntity family);

  /// Update an existing family
  Future<void> updateFamily(FamilyEntity family);

  /// Delete a family
  Future<void> deleteFamily(FamilyId familyId);

  /// Add a user to a family
  Future<void> addUserToFamily(FamilyId familyId, UserId userId);

  /// Remove a user from a family
  Future<void> removeUserFromFamily(FamilyId familyId, UserId userId);

  /// Stream family members
  Stream<List<User>> streamFamilyMembers(FamilyId familyId);

  /// Get family members
  Future<List<User>> getFamilyMembers(FamilyId familyId);

  /// Update a family member
  Future<void> updateFamilyMember(FamilyId familyId, UserId memberId, User member);

  /// Delete a family member
  Future<void> deleteFamilyMember(FamilyId familyId, UserId memberId);
} 