import 'package:hoque_family_chores/core/error/exceptions.dart';
import 'package:hoque_family_chores/domain/repositories/managed_child_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

/// In-memory [ManagedChildRepository]. [redeemLinkCode] returns the code as
/// the token, and MockAuthRepository.signInWithCustomToken signs in with the
/// token as the uid, so a test can pick the uid a link signs in as.
class MockManagedChildRepository implements ManagedChildRepository {
  final List<String> added = [];
  final List<UserId> removed = [];
  final List<UserId> linkCodesFor = [];

  /// Codes [redeemLinkCode] refuses, mapped to the server's message.
  final Map<String, String> refusedCodes = {};

  @override
  Future<UserId> addManagedChild(FamilyId familyId, String name) async {
    added.add(name);
    return UserId('managed_${added.length}');
  }

  @override
  Future<void> removeManagedChild(FamilyId familyId, UserId childId) async {
    removed.add(childId);
  }

  @override
  Future<LinkCode> createLinkCode(FamilyId familyId, UserId childId) async {
    linkCodesFor.add(childId);
    return LinkCode(
      code: 'ABCDEFGHJKMN',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
  }

  @override
  Future<String> redeemLinkCode(String code) async {
    final refusal = refusedCodes[code];
    if (refusal != null) {
      throw ValidationException(refusal, code: 'failed-precondition');
    }
    return code;
  }
}
