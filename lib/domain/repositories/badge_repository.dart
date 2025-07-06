import 'dart:async';
import '../entities/badge.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';
import '../../core/error/failures.dart';

/// Abstract interface for badge data operations
abstract class BadgeRepository {
  /// Stream user badges
  Stream<List<Badge>> streamUserBadges(UserId userId);

  /// Award a badge to a user
  Future<void> awardBadge(FamilyId familyId, UserId userId, String badgeId);

  /// Revoke a badge from a user
  Future<void> revokeBadge(FamilyId familyId, UserId userId, String badgeId);

  /// Get all badges for a family
  Future<List<Badge>> getBadges(FamilyId familyId);

  /// Create a new badge
  Future<void> createBadge(FamilyId familyId, Badge badge);

  /// Update an existing badge
  Future<void> updateBadge(FamilyId familyId, String badgeId, Badge badge);

  /// Delete a badge
  Future<void> deleteBadge(FamilyId familyId, String badgeId);
} 