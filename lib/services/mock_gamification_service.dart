import 'package:hoque_family_chores/models/badge.dart'; // Your custom Badge model
import 'package:hoque_family_chores/models/reward.dart'; // Your custom Reward model
// import 'package:hoque_family_chores/models/achievement.dart'; // <--- REMOVED UNUSED IMPORT
import 'package:hoque_family_chores/models/enums.dart'; // For BadgeCategory, BadgeRarity, RewardCategory, RewardRarity
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // Import mock_data for constants

class MockGamificationService implements GamificationServiceInterface {
  final List<Badge> _predefinedBadges = [
    Badge(
      id: MockData.badgeFirstTask,
      name: 'First Task!',
      description: 'Completed your very first chore.',
      imageUrl: 'assets/icons/star_border.png',
      category: BadgeCategory.taskMaster,
      rarity: BadgeRarity.common,
      requiredPoints: 10,
    ),
    Badge(
      id: MockData.badgeTaskMaster,
      name: 'Task Master',
      description: 'Completed 10 chores.',
      imageUrl: 'assets/icons/military_tech.png',
      category: BadgeCategory.taskMaster,
      rarity: BadgeRarity.rare,
      requiredPoints: 100,
    ),
    Badge(
      id: MockData.badgeConsistent,
      name: 'Consistent Helper',
      description: 'Completed a chore 7 days in a row.',
      imageUrl: 'assets/icons/local_fire_department.png',
      category: BadgeCategory.streaker,
      rarity: BadgeRarity.epic,
      requiredPoints: 500,
    ),
  ];

  final List<Reward> _predefinedRewards = [
    Reward(
      id: 'reward_movie_night',
      title: 'Movie Night Pick',
      description: 'You get to pick the movie for family movie night!',
      pointsCost: 500,
      iconName: 'theaters',
      category: RewardCategory.privilege,
      rarity: RewardRarity.rare,
      isAvailable: true,
    ),
    Reward(
      id: 'reward_ice_cream',
      title: 'Ice Cream Treat',
      description: 'A special ice cream treat, on the house.',
      pointsCost: 250,
      iconName: 'icecream',
      category: RewardCategory.physical,
      rarity: RewardRarity.uncommon,
      isAvailable: true,
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