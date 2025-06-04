// lib/services/family_service_interface.dart
import '../models/family_member.dart'; // Make sure this path to your FamilyMember model is correct

abstract class FamilyServiceInterface {
  /// Fetches a list of all registered family members.
  ///
  /// This method is expected to return a Future that completes with a List
  /// of [FamilyMember] objects.
  /// If an error occurs during the fetching process (e.g., network issue,
  /// server error), it should throw an [Exception] that can be caught
  /// by the caller (like our FamilyListProvider).
  Future<List<FamilyMember>> getFamilyMembers();

  // As your application grows, you might add more methods to this interface
  // to manage family members. For example:
  //
  // /// Fetches a single family member by their unique ID.
  // Future<FamilyMember?> getFamilyMemberById(String id);
  //
  // /// Adds a new family member.
  // Future<void> addFamilyMember(FamilyMember member);
  //
  // /// Updates an existing family member's details.
  // Future<void> updateFamilyMember(FamilyMember member);
  //
  // /// Deletes a family member by their unique ID.
  // Future<void> deleteFamilyMember(String id);
}