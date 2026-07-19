import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/family_repository.dart';
import '../../domain/entities/family.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of FamilyRepository
class FirebaseFamilyRepository implements FamilyRepository {
  final FirebaseFirestore _firestore;

  FirebaseFamilyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<FamilyEntity?> getFamily(FamilyId familyId) async {
    try {
      final doc = await _firestore.collection('families').doc(familyId.value).get();

      if (!doc.exists) return null;

      return _mapFirestoreToFamily(doc.data()!, doc.id);
    } catch (e) {
      throw ServerException('Failed to get family: $e', code: 'FAMILY_FETCH_ERROR');
    }
  }

  @override
  Future<List<FamilyEntity>> getFamiliesForUser(UserId userId) async {
    try {
      final snapshot = await _firestore
          .collection('families')
          .where('memberIds', arrayContains: userId.value)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToFamily(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get families for user: $e', code: 'FAMILY_FETCH_ERROR');
    }
  }

  @override
  Future<FamilyEntity?> getFamilyByInviteCode(String inviteCode) async {
    final familyId = await resolveInviteCode(inviteCode);
    if (familyId == null) return null;
    return getFamily(familyId);
  }

  @override
  Future<FamilyId?> resolveInviteCode(String inviteCode) async {
    try {
      // Invite codes resolve through familyInvites/{code}: security rules
      // allow fetching an invite by code but never listing families.
      final inviteDoc = await _firestore
          .collection('familyInvites')
          .doc(inviteCode)
          .get();

      if (!inviteDoc.exists) return null;

      final familyId = inviteDoc.data()?['familyId'] as String?;
      if (familyId == null || familyId.isEmpty) return null;

      return FamilyId(familyId);
    } catch (e) {
      throw ServerException('Failed to look up invite code: $e',
          code: 'FAMILY_INVITE_LOOKUP_ERROR');
    }
  }

  @override
  Future<void> requestToJoinFamily(
    FamilyId familyId,
    UserId userId,
    String inviteCode,
  ) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('joinRequests')
          .doc(userId.value)
          .set({'code': inviteCode});
    } catch (e) {
      throw ServerException('Failed to request to join family: $e',
          code: 'FAMILY_JOIN_REQUEST_ERROR');
    }
  }

  @override
  Future<void> createFamily(FamilyEntity family) async {
    try {
      await _firestore
          .collection('families')
          .doc(family.id.value)
          .set(_mapFamilyToFirestore(family));

      if (family.inviteCode.isNotEmpty) {
        await _firestore
            .collection('familyInvites')
            .doc(family.inviteCode)
            .set({'familyId': family.id.value});
      }
    } catch (e) {
      throw ServerException('Failed to create family: $e', code: 'FAMILY_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateFamily(FamilyEntity family) async {
    try {
      await _firestore
          .collection('families')
          .doc(family.id.value)
          .update(_mapFamilyToFirestore(family));
    } catch (e) {
      throw ServerException('Failed to update family: $e', code: 'FAMILY_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteFamily(FamilyId familyId) async {
    try {
      await _firestore.collection('families').doc(familyId.value).delete();
    } catch (e) {
      throw ServerException('Failed to delete family: $e', code: 'FAMILY_DELETE_ERROR');
    }
  }

  @override
  Future<void> addUserToFamily(FamilyId familyId, UserId userId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .update({
            'memberIds': FieldValue.arrayUnion([userId.value]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerException('Failed to add user to family: $e', code: 'FAMILY_ADD_MEMBER_ERROR');
    }
  }

  @override
  Future<void> removeUserFromFamily(FamilyId familyId, UserId userId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .update({
            'memberIds': FieldValue.arrayRemove([userId.value]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw ServerException('Failed to remove user from family: $e', code: 'FAMILY_REMOVE_MEMBER_ERROR');
    }
  }

  // Members live in the top-level `users` collection keyed by familyId;
  // the families/{id}/members subcollection is never populated.
  @override
  Stream<List<User>> streamFamilyMembers(FamilyId familyId) {
    return _firestore
        .collection('users')
        .where('familyId', isEqualTo: familyId.value)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToUser(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: familyId.value)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToUser(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get family members: $e', code: 'FAMILY_MEMBERS_FETCH_ERROR');
    }
  }

  @override
  Future<void> updateFamilyMember(FamilyId familyId, UserId memberId, User member) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('members')
          .doc(memberId.value)
          .update(_mapUserToFirestore(member));
    } catch (e) {
      throw ServerException('Failed to update family member: $e', code: 'FAMILY_MEMBER_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteFamilyMember(FamilyId familyId, UserId memberId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId.value)
          .collection('members')
          .doc(memberId.value)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete family member: $e', code: 'FAMILY_MEMBER_DELETE_ERROR');
    }
  }

  /// Maps Firestore document data to domain Family entity
  FamilyEntity _mapFirestoreToFamily(Map<String, dynamic> data, String id) {
    return FamilyEntity(
      id: FamilyId(id),
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      creatorId: UserId(data['creatorId'] as String? ?? ''),
      memberIds: List<String>.from(data['memberIds'] ?? [])
          .map((memberId) => UserId(memberId))
          .toList(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
      backgroundPhotoUrl: data['backgroundPhotoUrl'] as String?,
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }

  /// Maps domain Family entity to Firestore document data
  Map<String, dynamic> _mapFamilyToFirestore(FamilyEntity family) {
    return {
      'name': family.name,
      'description': family.description,
      'creatorId': family.creatorId.value,
      'memberIds': family.memberIds.map((id) => id.value).toList(),
      'createdAt': family.createdAt,
      'updatedAt': family.updatedAt,
      'photoUrl': family.photoUrl,
      'backgroundPhotoUrl': family.backgroundPhotoUrl,
      'inviteCode': family.inviteCode,
    };
  }

  /// Maps Firestore document data to domain User entity
  User _mapFirestoreToUser(Map<String, dynamic> data, String id) {
    // Children join anonymously with no email. User.email is nullable for
    // exactly that reason, so an absent one maps to null. The old code forced
    // it through Email(''), which throws 'Invalid email format' — and because
    // this runs inside a .map() over the whole family, one child took down the
    // entire members list (and the add-task picker that shares this query).
    // FirebaseUserRepository already parses email this way; this matches it.
    final rawEmail = data['email'] as String?;
    return User(
      id: UserId(id),
      name: data['name'] as String? ?? '',
      email: (rawEmail == null || rawEmail.isEmpty) ? null : Email(rawEmail),
      avatarEmoji: data['avatarEmoji'] as String?,
      photoUrl: data['photoUrl'] as String?,
      familyId: FamilyId(data['familyId'] as String? ?? ''),
      role: _mapStringToUserRole(data['role'] as String? ?? 'child'),
      points: Points(data['points'] as int? ?? 0),
      joinedAt: data['joinedAt'] is Timestamp
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  /// Maps domain User entity to Firestore document data
  Map<String, dynamic> _mapUserToFirestore(User user) {
    return {
      'name': user.name,
      'email': user.email?.value,
      'photoUrl': user.photoUrl,
      'familyId': user.familyId.value,
      'role': user.role.name,
      'points': user.points.toInt(),
      'joinedAt': user.joinedAt,
      'updatedAt': user.updatedAt,
    };
  }

  /// Maps string to UserRole enum
  UserRole _mapStringToUserRole(String role) {
    switch (role.toLowerCase()) {
      case 'parent':
        return UserRole.parent;
      case 'child':
        return UserRole.child;
      case 'guardian':
        return UserRole.guardian;
      case 'other':
        return UserRole.other;
      default:
        return UserRole.child;
    }
  }
} 