// lib/services/gamification_service_interface.dart

import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';

abstract class GamificationServiceInterface {
  Future<List<Badge>> getPredefinedBadges();
  Future<List<Reward>> getPredefinedRewards();
  // Add other gamification methods here as needed, e.g.:
  // Future<void> awardBadge(String userId, String badgeId);
}