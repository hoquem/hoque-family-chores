import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../domain/value_objects/family_id.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of UserRepository
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<User?> getUserProfile(UserId userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId.value).get();

      if (!doc.exists) return null;

      return mapFirestoreToUser(doc.data()!, doc.id);
    } catch (e) {
      throw ServerException('Failed to get user profile: $e', code: 'USER_FETCH_ERROR');
    }
  }

  @override
  Stream<User?> streamUserProfile(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .snapshots()
        .map((doc) => doc.exists ? mapFirestoreToUser(doc.data()!, doc.id) : null);
  }

  @override
  Future<void> createUserProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id.value)
          .set(_mapUserToFirestore(user));
    } catch (e) {
      throw ServerException('Failed to create user profile: $e', code: 'USER_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateUserProfile(User user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id.value)
          .update(_mapUserToFirestore(user));
    } catch (e) {
      throw ServerException('Failed to update user profile: $e', code: 'USER_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteUserProfile(UserId userId) async {
    try {
      await _firestore.collection('users').doc(userId.value).delete();
    } catch (e) {
      throw ServerException('Failed to delete user profile: $e', code: 'USER_DELETE_ERROR');
    }
  }

  @override
  Future<void> updateUserPoints(UserId userId, Points points) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .update({'points': points.toInt()});
    } catch (e) {
      throw ServerException('Failed to update user points: $e', code: 'USER_POINTS_UPDATE_ERROR');
    }
  }

  @override
  Future<void> addPoints(UserId userId, Points points) async {
    try {
      // Atomic increment: concurrent awards must not lose writes.
      await _firestore
          .collection('users')
          .doc(userId.value)
          .update({'points': FieldValue.increment(points.toInt())});
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to add points: $e', code: 'USER_ADD_POINTS_ERROR');
    }
  }

  @override
  Future<void> subtractPoints(UserId userId, Points points) async {
    try {
      // A transaction, not read-then-write.
      //
      // addPoints uses FieldValue.increment and says why: "concurrent awards
      // must not lose writes". This did the opposite — read the balance,
      // compute, write it back — so two claims landing together could both see
      // 200 stars and both spend them. Nobody had noticed because until
      // Rewards nothing ever called this.
      //
      // increment(-n) would be atomic but cannot refuse to go negative, and a
      // balance that can go below zero is worse than a lost write. So: read and
      // write inside one transaction, and reject the spend there.
      final ref = _firestore.collection('users').doc(userId.value);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) {
          throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
        }

        final current = (snapshot.data()?['points'] as num?)?.toInt() ?? 0;
        final remaining = current - points.toInt();
        if (remaining < 0) {
          throw ValidationException(
            'Not enough stars: $current available, ${points.toInt()} needed',
            code: 'INSUFFICIENT_POINTS',
          );
        }

        transaction.update(ref, {'points': remaining});
      });
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to subtract points: $e', code: 'USER_SUBTRACT_POINTS_ERROR');
    }
  }

  /// Maps Firestore document data to domain User entity.
  ///
  /// A document that cannot be parsed (e.g. a legacy schema without a
  /// top-level email) throws a [ServerException] with code
  /// `USER_DATA_MALFORMED` naming the document, so the failure surfaces
  /// instead of masquerading as a missing or half-empty profile.
  static User mapFirestoreToUser(Map<String, dynamic> data, String id) {
    try {
      // A user who has not created or joined a family yet stores an empty
      // familyId; that is a valid state, not a malformed document. Likewise
      // a missing email is valid — children join anonymously without one —
      // but a present, unparseable email is still malformed data.
      final rawFamilyId = data['familyId'] as String? ?? '';
      final rawEmail = data['email'] as String?;
      final rawName = data['name'] as String?;
      if (rawName == null || rawName.trim().isEmpty) {
        // Every user — adult or anonymous child — has a name; a document
        // without one is corrupt (e.g. the legacy nested schema).
        throw const FormatException('missing required field: name');
      }
      return User(
        id: UserId(id),
        name: rawName,
        email: (rawEmail == null || rawEmail.isEmpty) ? null : Email(rawEmail),
        photoUrl: data['photoUrl'] as String?,
        familyId: rawFamilyId.isEmpty ? FamilyId.empty : FamilyId(rawFamilyId),
        role: _mapStringToUserRole(data['role'] as String? ?? 'child'),
        points: Points(data['points'] as int? ?? 0),
        joinedAt: data['joinedAt'] is Timestamp
            ? (data['joinedAt'] as Timestamp).toDate()
            : DateTime.tryParse(data['joinedAt']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      throw ServerException(
        'User profile document users/$id could not be parsed: $e',
        code: 'USER_DATA_MALFORMED',
      );
    }
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
  static UserRole _mapStringToUserRole(String role) {
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