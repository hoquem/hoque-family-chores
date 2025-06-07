// lib/test_data/mock_data.dart

import 'package:hoque_family_chores/services/data_service.dart';

/// Provides mock data for testing and development purposes.
/// This data simulates what would be stored in Firebase.
class MockData {
  // Static user IDs for easy reference
  static const String parentUserId1 = 'user_parent_1';
  static const String parentUserId2 = 'user_parent_2';
  static const String childUserId1 = 'user_child_1';
  static const String childUserId2 = 'user_child_2';
  static const String childUserId3 = 'user_child_3';
  
  // Static family ID
  static const String familyId = 'family_hoque_1';

  // Static badge IDs
  static const String badgeFirstTask = 'badge_first_task';
  static const String badgeTaskMaster = 'badge_task_master';
  static const String badgeTeamPlayer = 'badge_team_player';
  static const String badgeConsistent = 'badge_consistent';
  
  // Static achievement IDs
  static const String achievementTaskStreak = 'achievement_task_streak';
  static const String achievementVarietyKing = 'achievement_variety_king';
  static const String achievementSuperHelper = 'achievement_super_helper';

  // Static task categories
  static const List<String> taskCategories = [
    'cleaning',
    'cooking',
    'outdoor',
    'homework',
    'pet_care',
    'laundry',
    'dishes',
    'shopping',
    'maintenance',
  ];

  /// Mock user profiles data
  static final List<Map<String, dynamic>> userProfiles = [
    {
      'id': parentUserId1,
      'displayName': 'Ahmed Hoque',
      'email': 'ahmed@example.com',
      'photoUrl': 'https://example.com/profiles/ahmed.jpg',
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
      'photoUrl': 'https://example.com/profiles/fatima.jpg',
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
      'photoUrl': 'https://example.com/profiles/zahra.jpg',
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
      'photoUrl': 'https://example.com/profiles/yusuf.jpg',
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
      'photoUrl': 'https://example.com/profiles/amina.jpg',
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
    'name': 'Hoque Family',
    'description': 'Working together to keep our home happy!',
    'photoUrl': 'https://example.com/families/hoque.jpg',
    'creatorUserId': parentUserId1,
    'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
    'memberCount': 5,
    'totalTasksCompleted': 324,
    'totalPoints': 4720,
  };

  /// Mock tasks data with varying statuses, difficulties, and categories
  static final List<Map<String, dynamic>> tasks = [
    {
      'id': 'task_1',
      'title': 'Clean the kitchen',
      'description': 'Wipe counters, clean sink, sweep and mop floor',
      'familyId': familyId,
      'difficulty': TaskDifficulty.medium.name,
      'assigneeId': childUserId1,
      'creatorId': parentUserId1,
      'status': TaskStatus.pending.name,
      'dueDate': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'categories': ['cleaning', 'kitchen'],
      'pointValue': 50,
      'bonusMultiplier': 1.0,
      'estimatedMinutes': 30,
      'isCollaborative': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      'subtasks': [
        {'title': 'Wipe counters', 'completed': false},
        {'title': 'Clean sink', 'completed': false},
        {'title': 'Sweep floor', 'completed': false},
        {'title': 'Mop floor', 'completed': false},
      ],
    },
    {
      'id': 'task_2',
      'title': 'Take out trash',
      'description': 'Collect all trash from bins and take to outdoor container',
      'familyId': familyId,
      'difficulty': TaskDifficulty.easy.name,
      'assigneeId': childUserId2,
      'creatorId': parentUserId1,
      'status': TaskStatus.completed.name,
      'dueDate': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'completedAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      'completedByUserId': childUserId2,
      'categories': ['cleaning', 'outdoor'],
      'pointValue': 20,
      'bonusMultiplier': 1.0,
      'estimatedMinutes': 10,
      'isCollaborative': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'completionNotes': 'All trash taken out and bins cleaned',
    },
    {
      'id': 'task_3',
      'title': 'Prepare dinner',
      'description': 'Cook pasta with vegetables and set the table',
      'familyId': familyId,
      'difficulty': TaskDifficulty.hard.name,
      'assigneeId': childUserId3,
      'creatorId': parentUserId2,
      'status': TaskStatus.verified.name,
      'dueDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'completedAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'completedByUserId': childUserId3,
      'verifiedAt': DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
      'verifiedByUserId': parentUserId2,
      'categories': ['cooking', 'kitchen'],
      'pointValue': 75,
      'bonusMultiplier': 1.2,
      'estimatedMinutes': 60,
      'isCollaborative': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'completionNotes': 'Made spaghetti with vegetables and garlic bread',
      'verificationNotes': 'Excellent job, very tasty!',
    },
    {
      'id': 'task_4',
      'title': 'Clean the bathroom',
      'description': 'Clean toilet, sink, shower, and floor',
      'familyId': familyId,
      'difficulty': TaskDifficulty.hard.name,
      'assigneeId': null, // Unassigned task
      'creatorId': parentUserId1,
      'status': TaskStatus.pending.name,
      'dueDate': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      'categories': ['cleaning', 'bathroom'],
      'pointValue': 70,
      'bonusMultiplier': 1.0,
      'estimatedMinutes': 45,
      'isCollaborative': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'subtasks': [
        {'title': 'Clean toilet', 'completed': false},
        {'title': 'Clean sink', 'completed': false},
        {'title': 'Clean shower', 'completed': false},
        {'title': 'Clean floor', 'completed': false},
      ],
    },
    {
      'id': 'task_5',
      'title': 'Yard work',
      'description': 'Mow the lawn and trim hedges',
      'familyId': familyId,
      'difficulty': TaskDifficulty.challenging.name,
      'assigneeId': childUserId2,
      'creatorId': parentUserId1,
      'status': TaskStatus.inProgress.name,
      'dueDate': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      'categories': ['outdoor', 'maintenance'],
      'pointValue': 100,
      'bonusMultiplier': 1.5,
      'estimatedMinutes': 90,
      'isCollaborative': true,
      'collaborators': [childUserId2, childUserId3],
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'subtasks': [
        {'title': 'Mow front lawn', 'completed': true},
        {'title': 'Mow back lawn', 'completed': false},
        {'title': 'Trim front hedges', 'completed': false},
        {'title': 'Trim back hedges', 'completed': false},
      ],
    },
    {
      'id': 'task_6',
      'title': 'Fold laundry',
      'description': 'Fold clean clothes and put them away',
      'familyId': familyId,
      'difficulty': TaskDifficulty.medium.name,
      'assigneeId': childUserId1,
      'creatorId': parentUserId2,
      'status': TaskStatus.completed.name,
      'dueDate': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      'completedAt': DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
      'completedByUserId': childUserId1,
      'categories': ['laundry', 'cleaning'],
      'pointValue': 40,
      'bonusMultiplier': 1.0,
      'estimatedMinutes': 30,
      'isCollaborative': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'completionNotes': 'All clothes folded and put away in the right drawers',
    },
  ];

  /// Mock badges data
  static final List<Map<String, dynamic>> badges = [
    {
      'id': badgeFirstTask,
      'name': 'First Task Complete',
      'description': 'Completed your first task',
      'iconUrl': 'https://example.com/badges/first_task.png',
      'pointValue': 50,
    },
    {
      'id': badgeTaskMaster,
      'name': 'Task Master',
      'description': 'Completed 10 tasks',
      'iconUrl': 'https://example.com/badges/task_master.png',
      'pointValue': 100,
    },
    {
      'id': badgeTeamPlayer,
      'name': 'Team Player',
      'description': 'Participated in 5 collaborative tasks',
      'iconUrl': 'https://example.com/badges/team_player.png',
      'pointValue': 150,
    },
    {
      'id': badgeConsistent,
      'name': 'Consistent Helper',
      'description': 'Completed tasks for 7 days in a row',
      'iconUrl': 'https://example.com/badges/consistent.png',
      'pointValue': 200,
    },
  ];

  /// Mock user badges (awarded badges to users)
  static final List<Map<String, dynamic>> userBadges = [
    {
      'userId': childUserId1,
      'badgeId': badgeFirstTask,
      'awardedAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      'reason': 'Completed first task: Fold laundry',
    },
    {
      'userId': childUserId1,
      'badgeId': badgeTaskMaster,
      'awardedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
      'reason': 'Completed 10 tasks',
    },
    {
      'userId': childUserId2,
      'badgeId': badgeFirstTask,
      'awardedAt': DateTime.now().subtract(const Duration(days: 28)).toIso8601String(),
      'reason': 'Completed first task: Take out trash',
    },
    {
      'userId': childUserId3,
      'badgeId': badgeFirstTask,
      'awardedAt': DateTime.now().subtract(const Duration(days: 29)).toIso8601String(),
      'reason': 'Completed first task: Prepare dinner',
    },
    {
      'userId': childUserId3,
      'badgeId': badgeTaskMaster,
      'awardedAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'reason': 'Completed 10 tasks',
    },
    {
      'userId': childUserId3,
      'badgeId': badgeTeamPlayer,
      'awardedAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'reason': 'Participated in 5 collaborative tasks',
    },
  ];

  /// Mock achievements data
  static final List<Map<String, dynamic>> achievements = [
    {
      'id': achievementTaskStreak,
      'name': 'Task Streak',
      'description': 'Complete tasks for consecutive days',
      'levels': [
        {'level': 1, 'requirement': 3, 'reward': 50, 'name': 'Bronze Streak'},
        {'level': 2, 'requirement': 7, 'reward': 100, 'name': 'Silver Streak'},
        {'level': 3, 'requirement': 14, 'reward': 200, 'name': 'Gold Streak'},
        {'level': 4, 'requirement': 30, 'reward': 500, 'name': 'Diamond Streak'},
      ],
    },
    {
      'id': achievementVarietyKing,
      'name': 'Variety King',
      'description': 'Complete tasks from different categories',
      'levels': [
        {'level': 1, 'requirement': 3, 'reward': 50, 'name': 'Variety Beginner'},
        {'level': 2, 'requirement': 5, 'reward': 100, 'name': 'Variety Pro'},
        {'level': 3, 'requirement': 7, 'reward': 200, 'name': 'Variety Expert'},
        {'level': 4, 'requirement': 9, 'reward': 300, 'name': 'Variety Master'},
      ],
    },
    {
      'id': achievementSuperHelper,
      'name': 'Super Helper',
      'description': 'Complete a large number of tasks',
      'levels': [
        {'level': 1, 'requirement': 10, 'reward': 100, 'name': 'Helper'},
        {'level': 2, 'requirement': 25, 'reward': 250, 'name': 'Super Helper'},
        {'level': 3, 'requirement': 50, 'reward': 500, 'name': 'Mega Helper'},
        {'level': 4, 'requirement': 100, 'reward': 1000, 'name': 'Ultimate Helper'},
      ],
    },
  ];

  /// Mock user achievements (progress of users toward achievements)
  static final List<Map<String, dynamic>> userAchievements = [
    {
      'userId': childUserId1,
      'achievementId': achievementTaskStreak,
      'currentLevel': 2,
      'currentProgress': 8,
      'lastUpdated': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
    },
    {
      'userId': childUserId1,
      'achievementId': achievementVarietyKing,
      'currentLevel': 1,
      'currentProgress': 3,
      'lastUpdated': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    },
    {
      'userId': childUserId2,
      'achievementId': achievementTaskStreak,
      'currentLevel': 1,
      'currentProgress': 4,
      'lastUpdated': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
    },
    {
      'userId': childUserId3,
      'achievementId': achievementTaskStreak,
      'currentLevel': 3,
      'currentProgress': 15,
      'lastUpdated': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'userId': childUserId3,
      'achievementId': achievementSuperHelper,
      'currentLevel': 2,
      'currentProgress': 28,
      'lastUpdated': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    },
  ];

  /// Mock notifications data
  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 'notif_1',
      'userId': childUserId1,
      'title': 'New Task Assigned',
      'message': 'You have been assigned to clean the kitchen',
      'type': 'task_assigned',
      'read': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 12)).toIso8601String(),
      'relatedId': 'task_1',
    },
    {
      'id': 'notif_2',
      'userId': childUserId2,
      'title': 'Task Verified',
      'message': 'Your task "Take out trash" has been verified',
      'type': 'task_verified',
      'read': true,
      'createdAt': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      'relatedId': 'task_2',
    },
    {
      'id': 'notif_3',
      'userId': childUserId3,
      'title': 'Badge Earned',
      'message': 'You earned the "Team Player" badge',
      'type': 'badge_earned',
      'read': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'relatedId': badgeTeamPlayer,
    },
    {
      'id': 'notif_4',
      'userId': parentUserId1,
      'title': 'Task Completed',
      'message': 'Zahra completed the task "Fold laundry"',
      'type': 'task_completed',
      'read': false,
      'createdAt': DateTime.now().subtract(const Duration(hours: 14)).toIso8601String(),
      'relatedId': 'task_6',
    },
  ];

  /// Mock task history data
  static final List<Map<String, dynamic>> taskHistory = [
    {
      'taskId': 'task_2',
      'action': 'created',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'userId': parentUserId1,
    },
    {
      'taskId': 'task_2',
      'action': 'assigned',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'userId': parentUserId1,
      'assigneeId': childUserId2,
    },
    {
      'taskId': 'task_2',
      'action': 'completed',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)).toIso8601String(),
      'userId': childUserId2,
      'notes': 'All trash taken out and bins cleaned',
    },
    {
      'taskId': 'task_3',
      'action': 'created',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'userId': parentUserId2,
    },
    {
      'taskId': 'task_3',
      'action': 'assigned',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'userId': parentUserId2,
      'assigneeId': childUserId3,
    },
    {
      'taskId': 'task_3',
      'action': 'completed',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'userId': childUserId3,
      'notes': 'Made spaghetti with vegetables and garlic bread',
    },
    {
      'taskId': 'task_3',
      'action': 'verified',
      'timestamp': DateTime.now().subtract(const Duration(days: 1, hours: 1)).toIso8601String(),
      'userId': parentUserId2,
      'notes': 'Excellent job, very tasty!',
    },
  ];

  /// Mock family statistics
  static final Map<String, dynamic> familyStats = {
    'familyId': familyId,
    'totalTasksCreated': 352,
    'totalTasksCompleted': 324,
    'totalTasksVerified': 310,
    'totalPoints': 4720,
    'tasksCompletedByCategory': {
      'cleaning': 120,
      'cooking': 85,
      'outdoor': 45,
      'homework': 30,
      'pet_care': 15,
      'laundry': 25,
      'dishes': 40,
      'shopping': 20,
      'maintenance': 10,
    },
    'tasksCompletedByUser': {
      childUserId1: 95,
      childUserId2: 89,
      childUserId3: 110,
      parentUserId1: 15,
      parentUserId2: 15,
    },
    'pointsByUser': {
      childUserId1: 850,
      childUserId2: 920,
      childUserId3: 1100,
      parentUserId1: 1500,
      parentUserId2: 1350,
    },
    'weeklyCompletion': [
      {'week': '2023-W22', 'count': 18},
      {'week': '2023-W23', 'count': 22},
      {'week': '2023-W24', 'count': 19},
      {'week': '2023-W25', 'count': 24},
      {'week': '2023-W26', 'count': 21},
    ],
  };
}
