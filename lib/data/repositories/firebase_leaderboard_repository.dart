import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of LeaderboardRepository
class FirebaseLeaderboardRepository implements LeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<User>> getLeaderboard(FamilyId familyId) async {
    try {
      // Get all users in the family
      final snapshot = await _firestore
          .collection('users')
          .where('familyId', isEqualTo: familyId.value)
          .orderBy('points', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapFirestoreToUser(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw ServerException('Failed to get leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
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