import 'dart:async';
import '../entities/achievement.dart';
import '../value_objects/user_id.dart';

/// Abstract interface for achievement data operations
abstract class AchievementRepository {
  /// Stream user achievements
  Stream<List<Achievement>> streamUserAchievements(UserId userId);

  /// Grant an achievement to a user
  Future<void> grantAchievement(UserId userId, Achievement achievement);

  /// Create a new achievement
  Future<void> createAchievement(String familyId, Achievement achievement);

  /// Update an existing achievement
  Future<void> updateAchievement(String familyId, String achievementId, Achievement achievement);

  /// Delete an achievement
  Future<void> deleteAchievement(String familyId, String achievementId);
} 