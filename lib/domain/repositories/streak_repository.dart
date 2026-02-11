import 'dart:async';
import '../entities/streak.dart';
import '../value_objects/user_id.dart';

/// Abstract interface for streak data operations
abstract class StreakRepository {
  /// Get a user's streak data
  Future<Streak?> getStreak(UserId userId);

  /// Stream streak data changes
  Stream<Streak?> streamStreak(UserId userId);

  /// Create initial streak data for a user
  Future<void> createStreak(Streak streak);

  /// Update streak data
  Future<void> updateStreak(Streak streak);

  /// Increment streak after quest completion
  Future<Streak> incrementStreak(UserId userId, DateTime completionDate);

  /// Reset streak to 0 (when missed day without freeze)
  Future<Streak> resetStreak(UserId userId);

  /// Use a freeze to protect streak
  Future<Streak> useFreeze(UserId userId);

  /// Purchase a streak freeze with stars
  Future<Streak> purchaseFreeze(UserId userId);

  /// Award milestone bonus stars
  Future<void> awardMilestoneBonus(UserId userId, int milestoneDay, int starAmount);
}
