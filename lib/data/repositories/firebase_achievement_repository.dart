import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/badge.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of AchievementRepository
class FirebaseAchievementRepository implements AchievementRepository {
  final FirebaseFirestore _firestore;

  FirebaseAchievementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Achievement>> streamUserAchievements(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('achievements')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _mapFirestoreToAchievement(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> grantAchievement(UserId userId, Achievement achievement) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('achievements')
          .doc(achievement.id)
          .set(_mapAchievementToFirestore(achievement));
    } catch (e) {
      throw ServerException('Failed to grant achievement: $e', code: 'ACHIEVEMENT_GRANT_ERROR');
    }
  }

  @override
  Future<void> createAchievement(String familyId, Achievement achievement) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('achievements')
          .doc(achievement.id)
          .set(_mapAchievementToFirestore(achievement));
    } catch (e) {
      throw ServerException('Failed to create achievement: $e', code: 'ACHIEVEMENT_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateAchievement(String familyId, String achievementId, Achievement achievement) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('achievements')
          .doc(achievementId)
          .update(_mapAchievementToFirestore(achievement));
    } catch (e) {
      throw ServerException('Failed to update achievement: $e', code: 'ACHIEVEMENT_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteAchievement(String familyId, String achievementId) async {
    try {
      await _firestore
          .collection('families')
          .doc(familyId)
          .collection('achievements')
          .doc(achievementId)
          .delete();
    } catch (e) {
      throw ServerException('Failed to delete achievement: $e', code: 'ACHIEVEMENT_DELETE_ERROR');
    }
  }

  /// Maps Firestore document data to domain Achievement entity
  Achievement _mapFirestoreToAchievement(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      points: Points(data['points'] as int? ?? 0),
      icon: data['icon'] as String? ?? '',
      type: _mapStringToBadgeType(data['type'] as String? ?? 'taskCompletion'),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: data['completedAt'] is Timestamp
          ? (data['completedAt'] as Timestamp).toDate()
          : data['completedAt'] != null
              ? DateTime.tryParse(data['completedAt'].toString())
              : null,
      completedBy: data['completedBy'] as String?,
    );
  }

  /// Maps domain Achievement entity to Firestore document data
  Map<String, dynamic> _mapAchievementToFirestore(Achievement achievement) {
    return {
      'title': achievement.title,
      'description': achievement.description,
      'points': achievement.points.toInt(),
      'icon': achievement.icon,
      'type': achievement.type.name,
      'createdAt': achievement.createdAt,
      'completedAt': achievement.completedAt,
      'completedBy': achievement.completedBy,
    };
  }

  /// Maps string to BadgeType enum
  BadgeType _mapStringToBadgeType(String type) {
    switch (type.toLowerCase()) {
      case 'taskcompletion':
        return BadgeType.taskCompletion;
      case 'streak':
        return BadgeType.streak;
      case 'points':
        return BadgeType.points;
      case 'special':
        return BadgeType.special;
      case 'custom':
        return BadgeType.custom;
      case 'achievement':
        return BadgeType.achievement;
      case 'milestone':
        return BadgeType.milestone;
      default:
        return BadgeType.taskCompletion;
    }
  }
} 