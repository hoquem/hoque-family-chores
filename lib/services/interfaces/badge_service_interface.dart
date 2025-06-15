import 'package:hoque_family_chores/models/badge.dart';

abstract class BadgeServiceInterface {
  Stream<List<Badge>> streamUserBadges({required String userId});
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  });
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  });
  Future<List<Badge>> getBadges({required String familyId});
  Future<void> createBadge({required String familyId, required Badge badge});
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  });
  Future<void> deleteBadge({required String familyId, required String badgeId});
}
