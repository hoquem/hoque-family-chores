import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// A one-time code that moves a managed child onto their own phone.
class LinkCode {
  const LinkCode({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;
}

/// Children with no phone of their own. Every operation runs server-side
/// (Cloud Functions in functions/managedChildren.js); the rules forbid
/// clients from writing `managed` or `profileLinks`.
abstract class ManagedChildRepository {
  /// Adds a child by name to [familyId]. Returns the new member's id.
  Future<UserId> addManagedChild(FamilyId familyId, String name);

  /// Removes a managed child for good: chores go back to the pool.
  Future<void> removeManagedChild(FamilyId familyId, UserId childId);

  /// A fresh code for [childId], replacing any earlier one.
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId);

  /// Spends [code]. Returns a custom token that signs in as the child.
  Future<String> redeemLinkCode(String code);
}
