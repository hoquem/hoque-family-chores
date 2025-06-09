// lib/services/gamification_service.dart

import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';

// This is a mock implementation for development and testing.
// A FirebaseGamificationService would fetch this data from Firestore collections.
class MockGamificationService implements GamificationServiceInterface {

  @override
  Future<List<Badge>> getPredefinedBadges() async {
    // In a real app, this would come from a 'badges' collection in Firestore.
    // For now, we return a hardcoded list.
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network latency
    return [
      Badge(
        id: 'task_master_1',
        title: 'Task Novice',
        description: 'Complete 5 tasks.',
        iconName: 'star_border',
        color: '#FFA500',
        rarity: BadgeRarity.common,
        requiredPoints: 0,
        category: BadgeCategory.taskMaster,
      ),
      Badge(
        id: 'streaker_1',
        title: 'Daily Doer',
        description: 'Complete a task 2 days in a row.',
        iconName: 'local_fire_department',
        color: '#FF4500',
        rarity: BadgeRarity.uncommon,
        requiredPoints: 0,
        category: BadgeCategory.streaker,
      ),
      // Add more predefined badges here...
    ];
  }

  @override
  Future<List<Reward>> getPredefinedRewards() async {
    // In a real app, this would come from a 'rewards' collection in Firestore.
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate network latency
    return [
      Reward(
        id: 'reward_movie_night',
        title: 'Movie Night Pick',
        description: 'You get to pick the movie for family movie night!',
        pointsCost: 500,
        iconName: 'theaters',
        category: RewardCategory.privilege,
        rarity: RewardRarity.rare,
      ),
      Reward(
        id: 'reward_ice_cream',
        title: 'Ice Cream Treat',
        description: 'A special ice cream treat, on the house.',
        pointsCost: 250,
        iconName: 'icecream',
        category: RewardCategory.physical,
        rarity: RewardRarity.uncommon,
      ),
      // Add more predefined rewards here...
    ];
  }
}