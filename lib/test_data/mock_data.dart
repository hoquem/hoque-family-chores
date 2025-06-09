// lib/test_data/mock_data.dart

import 'package:hoque_family_chores/models/enums.dart';

/// Provides a rich and comprehensive set of mock data for testing and development.
/// This data simulates what would be stored in a Firestore database.
class MockData {
  // --- STATIC IDENTIFIERS ---

  // User IDs
  static const String parentUserId1 = 'user_parent_1';
  static const String parentUserId2 = 'user_parent_2';
  static const String childUserId1 = 'user_child_1';
  static const String childUserId2 = 'user_child_2';
  static const String childUserId3 = 'user_child_3';
  
  // Family ID
  static const String familyId = 'family_hoque_1';

  // Badge IDs
  static const String badgeFirstTask = 'badge_first_task';
  static const String badgeTaskMaster = 'badge_task_master';
  static const String badgeTeamPlayer = 'badge_team_player';
  static const String badgeConsistent = 'badge_consistent';
  
  // Achievement IDs
  static const String achievementTaskStreak = 'achievement_task_streak';
  static const String achievementVarietyKing = 'achievement_variety_king';
  static const String achievementSuperHelper = 'achievement_super_helper';

  // --- MOCK DATA COLLECTIONS ---

  /// Mock user profiles data
  static final List<Map<String, dynamic>> userProfiles = [
    {
      'id': parentUserId1,
      'displayName': 'Ahmed Hoque',
      'email': 'ahmed@example.com',
      'photoUrl': 'https://i.pravatar.cc/150?u=ahmed',
      'role': FamilyRole.parent.name,
      'familyId': familyId,
      'points': 1500,
      'level': 5,
      'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'lastActive': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
    },
    {
      'id': parentUserId2,
      'displayName': 'Fatima Hoque',
      'email': 'fatima@example.com',
      'photoUrl': 'https://i.pravatar.cc/150?u=fatima',
      'role': FamilyRole.parent.name,
      'familyId': familyId,
      'points': 1350,
      'level': 4,
      'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
      'lastActive': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
    },
    {
      'id': childUserId1,
      'displayName': 'Zahra Hoque',
      'email': 'zahra@example.com',
      'photoUrl': 'https://i.pravatar.cc/150?u=zahra',
      'role': FamilyRole.child.name,
      'familyId': familyId,
      'points': 850,
      'level': 3,
      'createdAt': DateTime.now().subtract(const Duration(days: 150)).toIso8601String(),
      'lastActive': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': childUserId2,
      'displayName': 'Yusuf Hoque',
      'email': 'yusuf@example.com',
      'photoUrl': 'https://i.pravatar.cc/150?u=yusuf',
      'role': FamilyRole.child.name,
      'familyId': familyId,
      'points': 920,
      'level': 3,
      'createdAt': DateTime.now().subtract(const Duration(days: 150)).toIso8601String(),
      'lastActive': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': childUserId3,
      'displayName': 'Amina Hoque',
      'email': 'amina@example.com',
      'photoUrl': 'https://i.pravatar.cc/150?u=amina',
      'role': FamilyRole.child.name,
      'familyId': familyId,
      'points': 1100,
      'level': 4,
      'createdAt': DateTime.now().subtract(const Duration(days: 150)).toIso8601String(),
      'lastActive': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
  ];

  /// Mock family data
  static final Map<String, dynamic> family = {
    'id': familyId,
    'name': 'The Hoque Family',
    'description': 'Working together to keep our home happy and tidy!',
    'photoUrl': 'https://example.com/families/hoque.jpg',
    'creatorUserId': parentUserId1,
    'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
    'memberCount': 5,
  };

  /// Mock tasks data
  static final List<Map<String, dynamic>> tasks = [
    {
      'id': 'task_1',
      'title': 'Clean the kitchen',
      'description': 'Wipe counters, clean sink, sweep and mop floor.',
      'familyId': familyId,
      'difficulty': TaskDifficulty.medium.name,
      'assigneeId': childUserId1,
      'assigneeName': 'Zahra Hoque',
      'creatorId': parentUserId1,
      'status': TaskStatus.inProgress.name,
      'dueDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'pointValue': 50,
      'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
    },
    {
      'id': 'task_2',
      'title': 'Take out trash',
      'description': 'Collect all trash and take to outdoor container.',
      'familyId': familyId,
      'difficulty': TaskDifficulty.easy.name,
      'assigneeId': childUserId2,
      'assigneeName': 'Yusuf Hoque',
      'creatorId': parentUserId1,
      'status': TaskStatus.completed.name,
      'dueDate': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'pointValue': 20,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 'task_3',
      'title': 'Prepare dinner',
      'description': 'Cook pasta with vegetables and set the table.',
      'familyId': familyId,
      'difficulty': TaskDifficulty.hard.name,
      'assigneeId': childUserId3,
      'assigneeName': 'Amina Hoque',
      'creatorId': parentUserId2,
      'status': TaskStatus.verified.name,
      'dueDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'pointValue': 75,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'id': 'task_4',
      'title': 'Clean the guest bathroom',
      'description': 'Clean toilet, sink, shower, and floor.',
      'familyId': familyId,
      'difficulty': TaskDifficulty.hard.name,
      'assigneeId': null,
      'assigneeName': null,
      'creatorId': parentUserId1,
      'status': TaskStatus.pending.name,
      'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'pointValue': 70,
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
    },
    {
      'id': 'task_5',
      'title': 'Walk the dog',
      'description': 'Take Charlie for a 30-minute walk around the park.',
      'familyId': familyId,
      'difficulty': TaskDifficulty.easy.name,
      'assigneeId': null,
      'assigneeName': null,
      'creatorId': parentUserId2,
      'status': TaskStatus.pending.name,
      'dueDate': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      'pointValue': 15,
      'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
  ];

  /// Mock badge definitions
  static final List<Map<String, dynamic>> badges = [
    {
      'id': badgeFirstTask,
      'title': 'First Task!',
      'description': 'Completed your very first chore.',
      'iconName': 'star_border',
      'color': '#FFC107',
      'rarity': BadgeRarity.common.name,
      'category': BadgeCategory.taskMaster.name,
    },
    {
      'id': badgeTaskMaster,
      'title': 'Task Master',
      'description': 'Completed 10 chores.',
      'iconName': 'military_tech',
      'color': '#03A9F4',
      'rarity': BadgeRarity.rare.name,
      'category': BadgeCategory.taskMaster.name,
    },
    {
      'id': badgeConsistent,
      'title': 'Consistent Helper',
      'description': 'Completed a chore 7 days in a row.',
      'iconName': 'local_fire_department',
      'color': '#F44336',
      'rarity': BadgeRarity.epic.name,
      'category': BadgeCategory.streaker.name,
    },
  ];

  /// Mock reward definitions
  static final List<Map<String, dynamic>> rewards = [
    {
      'id': 'reward_movie_night',
      'title': 'Movie Night Pick',
      'description': 'You get to pick the movie for family movie night!',
      'pointsCost': 500,
      'iconName': 'theaters',
      'category': RewardCategory.privilege.name,
      'rarity': RewardRarity.rare.name,
      'isAvailable': true,
    },
    {
      'id': 'reward_ice_cream',
      'title': 'Ice Cream Treat',
      'description': 'A special ice cream treat, on the house.',
      'pointsCost': 250,
      'iconName': 'icecream',
      'category': RewardCategory.physical.name,
      'rarity': RewardRarity.uncommon.name,
      'isAvailable': true,
    },
    {
      'id': 'reward_game_time',
      'title': 'Extra Game Time',
      'description': '30 extra minutes of video game time.',
      'pointsCost': 150,
      'iconName': 'sports_esports',
      'category': RewardCategory.digital.name,
      'rarity': RewardRarity.common.name,
      'isAvailable': true,
    },
    {
      'id': 'reward_no_chore',
      'title': 'One Chore-Free Day',
      'description': 'Get a pass on one of your assigned chores.',
      'pointsCost': 1000,
      'iconName': 'cancel_schedule_send',
      'category': RewardCategory.privilege.name,
      'rarity': RewardRarity.rare.name,
      'isAvailable': false,
    },
  ];
}