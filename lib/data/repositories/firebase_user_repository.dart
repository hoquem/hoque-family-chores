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

      return _mapFirestoreToUser(doc.data()!, doc.id);
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
        .map((doc) => doc.exists ? _mapFirestoreToUser(doc.data()!, doc.id) : null);
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
      final user = await getUserProfile(userId);
      if (user == null) {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }

      final newPoints = user.points.add(points);
      await updateUserPoints(userId, newPoints);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to add points: $e', code: 'USER_ADD_POINTS_ERROR');
    }
  }

  @override
  Future<void> subtractPoints(UserId userId, Points points) async {
    try {
      final user = await getUserProfile(userId);
      if (user == null) {
        throw NotFoundException('User not found', code: 'USER_NOT_FOUND');
      }

      final newPoints = user.points.subtract(points);
      await updateUserPoints(userId, newPoints);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to subtract points: $e', code: 'USER_SUBTRACT_POINTS_ERROR');
    }
  }

  /// Maps Firestore document data to domain User entity
  User _mapFirestoreToUser(Map<String, dynamic> data, String id) {
    return User(
      id: UserId(id),
      name: data['name'] as String? ?? '',
      email: Email(data['email'] as String? ?? ''),
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
      'email': user.email.value,
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