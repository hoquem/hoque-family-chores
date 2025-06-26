import 'package:hoque_family_chores/models/badge.dart'; // Your custom Badge model
import 'package:hoque_family_chores/models/reward.dart'; // Your custom Reward model
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // Import mock_data for constants

class MockGamificationService implements GamificationServiceInterface {
  final List<Badge> _predefinedBadges = [
    Badge(
      id: MockData.badgeFirstTask,
      name: 'First Task!',
      description: 'Completed your very first chore.',
      iconName: 'star_border',
      requiredPoints: 10,
      type: BadgeType.taskCompletion,
      familyId: 'family_hoque_1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      rarity: BadgeRarity.common,
    ),
    Badge(
      id: MockData.badgeTaskMaster,
      name: 'Task Master',
      description: 'Completed 10 chores.',
      iconName: 'military_tech',
      requiredPoints: 100,
      type: BadgeType.taskCompletion,
      familyId: 'family_hoque_1',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
      rarity: BadgeRarity.rare,
    ),
    Badge(
      id: MockData.badgeConsistent,
      name: 'Consistent Helper',
      description: 'Completed a chore 7 days in a row.',
      iconName: 'local_fire_department',
      requiredPoints: 500,
      type: BadgeType.streak,
      familyId: 'family_hoque_1',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
      rarity: BadgeRarity.epic,
    ),
  ];

  final List<Reward> _predefinedRewards = [
    Reward(
      id: 'reward_movie_night',
      name: 'Movie Night Pick',
      description: 'You get to pick the movie for family movie night!',
      pointsCost: 500,
      iconName: 'theaters',
      type: RewardType.privilege,
      familyId: 'family_hoque_1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      rarity: RewardRarity.rare,
    ),
    Reward(
      id: 'reward_ice_cream',
      name: 'Ice Cream Treat',
      description: 'A special ice cream treat, on the house.',
      pointsCost: 250,
      iconName: 'icecream',
      type: RewardType.physical,
      familyId: 'family_hoque_1',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
      rarity: RewardRarity.uncommon,
    ),
  ];

  MockGamificationService() {
    logger.i("MockGamificationService initialized with dummy predefined data.");
  }

  @override
  Future<List<Badge>> getPredefinedBadges() async {
    logger.d("MockGamificationService: Providing predefined badges.");
    await Future.delayed(const Duration(milliseconds: 50));
    return _predefinedBadges;
  }

  @override
  Future<List<Reward>> getPredefinedRewards() async {
    logger.d("MockGamificationService: Providing predefined rewards.");
    await Future.delayed(const Duration(milliseconds: 50));
    return _predefinedRewards;
  }
}