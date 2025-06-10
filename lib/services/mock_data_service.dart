// lib/services/mock_data_service.dart
import 'dart:async'; // Required for StreamController
import 'package:hoque_family_chores/models/user_profile.dart'; // Use UserProfile
import 'package:hoque_family_chores/models/family_member.dart'; // Use FamilyMember
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart'; // Ensure this exists
import 'package:hoque_family_chores/models/notification.dart' as app_notification; // Use aliased name
import 'package:hoque_family_chores/models/task.dart'; // Ensure Task is imported
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // For initial data
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus

class MockDataService implements DataServiceInterface {
  // Use private fields to hold mock data - these will now be used
  final Map<String, UserProfile> _userProfiles = {
    for (var userData in MockData.userProfiles)
      userData['id'] as String: UserProfile.fromMap(userData),
  };

  final Map<String, List<Badge>> _userBadges = {
    // Populate with mock badges from MockData, ensuring Badge.fromMap exists
    MockData.childUserId1: [
      Badge.fromMap({'id': MockData.badgeFirstTask, 'name': 'First Task!', 'imageUrl': 'url', 'description': 'Completed first chore', 'isUnlocked': true, 'unlockedAt': DateTime.now()}),
    ],
  };
  final Map<String, List<Achievement>> _userAchievements = {
    // Populate with mock achievements
    MockData.childUserId1: [
      Achievement.fromMap({'id': MockData.achievementTaskStreak, 'title': 'Task Streak!', 'dateAwarded': DateTime.now()}),
    ],
  };
  final Map<String, List<app_notification.Notification>> _notifications = {
    // Populate with mock notifications
    MockData.childUserId1: [
      app_notification.Notification.fromMap({
        'id': 'notif_1',
        'message': 'Welcome to Family Chores!',
        'type': 'general',
        'timestamp': DateTime.now(),
        'read': false,
      }),
    ],
  };

  final Map<String, Map<String, Task>> _tasks = {}; // familyId -> (taskId -> Task)

  // Stream controllers to simulate real-time updates for mock data
  final StreamController<UserProfile?> _userProfileStreamController = StreamController<UserProfile?>.broadcast();
  final StreamController<List<Badge>> _userBadgesStreamController = StreamController<List<Badge>>.broadcast();
  final StreamController<List<Achievement>> _userAchievementsStreamController = StreamController<List<Achievement>>.broadcast();
  final StreamController<List<app_notification.Notification>> _notificationsStreamController = StreamController<List<app_notification.Notification>>.broadcast();
  final StreamController<List<Task>> _tasksStreamController = StreamController<List<Task>>.broadcast();

  MockDataService() {
    _userProfiles.forEach((userId, userProfile) => _userProfileStreamController.add(userProfile));
    _userBadges.forEach((userId, badges) => _userBadgesStreamController.add(badges));
    _userAchievements.forEach((userId, achievements) => _userAchievementsStreamController.add(achievements));
    _notifications.forEach((userId, notifications) => _notificationsStreamController.add(notifications));
    if (_tasks.isNotEmpty) {
      _tasksStreamController.add(_getAllTasks());
    }
    logger.i("MockDataService initialized with dummy data for immediate stream emission.");
  }

  // --- User Profile Methods ---
  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    logger.d("Mock: Streaming user profile with ID: $userId.");
    return _userProfileStreamController.stream.map((user) => _userProfiles[userId]).distinct();
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) async {
    logger.d("Mock: Getting user profile with ID: $userId.");
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network delay
    return _userProfiles[userId];
  }

  @override
  Future<void> updateUserProfile({required UserProfile user}) async {
    logger.d("Mock: Updating user profile ${user.id}.");
    _userProfiles[user.id] = user;
    _userProfileStreamController.add(user);
  }

  @override
  Future<void> deleteUser({required String userId}) async {
    logger.d("Mock: Deleting user $userId.");
    _userProfiles.remove(userId);
    _userProfileStreamController.add(null);
  }

  @override
  Future<void> updateUserPoints({required String userId, required int points}) async {
    logger.d("Mock: Updating points for user $userId by $points.");
    final currentUserProfile = _userProfiles[userId];
    if (currentUserProfile != null) {
      _userProfiles[userId] = currentUserProfile.copyWith(totalPoints: currentUserProfile.totalPoints + points);
      _userProfileStreamController.add(_userProfiles[userId]);
    } else {
      logger.w("Mock: User profile $userId not found for points update.");
    }
  }

  // --- Family Member Methods ---
  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    logger.d("Mock: Streaming family members for family ID: $familyId.");
    // Filter _userProfiles to get family members for the given familyId
    return _userProfileStreamController.stream.map((event) {
      return _userProfiles.values
          .where((profile) => profile.familyId == familyId)
          .map((profile) => FamilyMember.fromMap(profile.toJson()..['id'] = profile.id)) // Convert back to FamilyMember
          .toList();
    }).distinct();
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({required String familyId}) async {
    logger.d("Mock: Getting family members for family ID: $familyId.");
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate network delay
    return _userProfiles.values
        .where((profile) => profile.familyId == familyId)
        .map((profile) => FamilyMember.fromMap(profile.toJson()..['id'] = profile.id))
        .toList();
  }

  // --- Badge Related Methods ---
  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    logger.d("Mock: Streaming badges for user ID: $userId.");
    return _userBadgesStreamController.stream.map((badges) => _userBadges[userId] ?? []).distinct();
  }

  @override
  Future<void> awardBadge({required String userId, required Badge badge}) async {
    logger.d("Mock: Awarding badge ${badge.id} to user $userId.");
    _userBadges.putIfAbsent(userId, () => []).add(badge);
    _userBadgesStreamController.add(_userBadges[userId]!);
  }

  // --- Achievement Related Methods ---
  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    logger.d("Mock: Streaming achievements for user ID: $userId.");
    return _userAchievementsStreamController.stream.map((achievements) => _userAchievements[userId] ?? []).distinct();
  }

  @override
  Future<void> grantAchievement({required String userId, required Achievement achievement}) async {
    logger.d("Mock: Granting achievement ${achievement.id} to user $userId.");
    _userAchievements.putIfAbsent(userId, () => []).add(achievement);
    _userAchievementsStreamController.add(_userAchievements[userId]!);
  }

  // --- Notification Related Methods ---
  @override
  Stream<List<app_notification.Notification>> streamNotifications({required String userId}) {
    logger.d("Mock: Streaming notifications for user ID: $userId.");
    return _notificationsStreamController.stream.map((notifications) => _notifications[userId] ?? []).distinct();
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    logger.d("Mock: Marking notification $notificationId as read.");
    bool updated = false;
    _notifications.forEach((userId, notificationList) {
      final index = notificationList.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notificationList[index] = notificationList[index].copyWith(read: true);
        updated = true;
      }
    });
    if (updated) {
      _notifications.forEach((userId, notifications) {
        _notificationsStreamController.add(notifications);
      });
    } else {
      logger.w("Mock: Notification with ID $notificationId not found to mark as read.");
    }
  }

  // --- Task-related methods ---
  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    logger.d("Mock: Streaming tasks for family ID: $familyId");
    return _tasksStreamController.stream.map((tasks) => 
      tasks.where((task) => task.familyId == familyId).toList()
    ).distinct();
  }

  @override
  Future<Task?> getTask({required String familyId, required String taskId}) async {
    logger.d("Mock: Getting task $taskId for family $familyId");
    await Future.delayed(const Duration(milliseconds: 50));
    return _tasks[familyId]?[taskId];
  }

  @override
  Future<void> createTask({required String familyId, required Task task}) async {
    logger.d("Mock: Creating task ${task.id} for family $familyId");
    if (!_tasks.containsKey(familyId)) {
      _tasks[familyId] = {};
    }
    _tasks[familyId]![task.id] = task;
    _tasksStreamController.add(_getAllTasks());
  }

  @override
  Future<void> updateTask({required String familyId, required Task task}) async {
    logger.d("Mock: Updating task ${task.id} for family $familyId");
    if (_tasks[familyId]?[task.id] != null) {
      _tasks[familyId]![task.id] = task;
      _tasksStreamController.add(_getAllTasks());
    }
  }

  @override
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}) async {
    logger.d("Mock: Updating task $taskId status to $newStatus for family $familyId");
    final task = _tasks[familyId]?[taskId];
    if (task != null) {
      _tasks[familyId]![taskId] = task.copyWith(status: newStatus);
      _tasksStreamController.add(_getAllTasks());
    }
  }

  @override
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId}) async {
    logger.d("Mock: Assigning task $taskId to user $assigneeId in family $familyId");
    final task = _tasks[familyId]?[taskId];
    if (task != null) {
      _tasks[familyId]![taskId] = task.copyWith(assigneeId: assigneeId);
      _tasksStreamController.add(_getAllTasks());
    }
  }

  @override
  Future<void> deleteTask({required String familyId, required String taskId}) async {
    logger.d("Mock: Deleting task $taskId from family $familyId");
    _tasks[familyId]?.remove(taskId);
    _tasksStreamController.add(_getAllTasks());
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}) {
    logger.d("Mock: Streaming tasks for assignee $assigneeId in family $familyId");
    return _tasksStreamController.stream.map((tasks) => 
      tasks.where((task) => 
        task.familyId == familyId && task.assigneeId == assigneeId
      ).toList()
    ).distinct();
  }

  // Helper method to get all tasks
  List<Task> _getAllTasks() {
    return _tasks.values.expand((taskMap) => taskMap.values).toList();
  }

  void dispose() {
    _userProfileStreamController.close();
    _userBadgesStreamController.close();
    _userAchievementsStreamController.close();
    _notificationsStreamController.close();
    _tasksStreamController.close();
    logger.i("MockDataService disposed.");
  }
}