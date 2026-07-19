import 'dart:async';
import '../entities/family.dart';
import '../entities/user.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// Repository interface for family-related operations
abstract class FamilyRepository {
  /// Get a family by its ID
  Future<FamilyEntity?> getFamily(FamilyId familyId);

  /// Get all families for a specific user
  Future<List<FamilyEntity>> getFamiliesForUser(UserId userId);

  /// Get a family by its invite code, or null if no family matches
  Future<FamilyEntity?> getFamilyByInviteCode(String inviteCode);

  /// Resolves an invite code to its family id via the familyInvites lookup,
  /// without reading the family document (which now requires membership or a
  /// join request). Returns null if the code is unknown.
  Future<FamilyId?> resolveInviteCode(String inviteCode);

  /// Records a validated join request proving [userId] holds [inviteCode] for
  /// [familyId]. Must be called before adding the user to the family — the
  /// security rules gate both the family read and the memberIds self-add on it.
  Future<void> requestToJoinFamily(
    FamilyId familyId,
    UserId userId,
    String inviteCode,
  );

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