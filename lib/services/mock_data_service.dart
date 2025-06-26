import 'dart:async';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/notification.dart'
    as app_notification;
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // For initial data

class MockDataService implements DataServiceInterface {
  // Use private fields to hold mock data
  final Map<String, UserProfile> _userProfiles = {
    for (var userData in MockData.userProfiles)
      userData['id'] as String: UserProfile.fromMap(userData),
  };

  final Map<String, Family> _families = {
    MockData.familyId: Family.fromMap(MockData.family),
  };

  final Map<String, List<Badge>> _userBadges = {
    MockData.childUserId1: [
      Badge.fromMap({
        'id': MockData.badgeFirstTask,
        'name': 'First Task!',
        'imageUrl': 'url',
        'description': 'Completed first chore',
        'isUnlocked': true,
        'unlockedAt': DateTime.now(),
      }),
    ],
  };
  final Map<String, List<Achievement>> _userAchievements = {
    MockData.childUserId1: [
      Achievement.fromMap({
        'id': MockData.achievementTaskStreak,
        'title': 'Task Streak!',
        'dateAwarded': DateTime.now(),
      }),
    ],
  };
  final Map<String, List<app_notification.Notification>> _notifications = {
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

  // Stream controllers to simulate real-time updates for mock data
  final StreamController<UserProfile?> _userProfileStreamController =
      StreamController<UserProfile?>.broadcast();
  final StreamController<List<Badge>> _userBadgesStreamController =
      StreamController<List<Badge>>.broadcast();
  final StreamController<List<Achievement>> _userAchievementsStreamController =
      StreamController<List<Achievement>>.broadcast();
  final StreamController<List<app_notification.Notification>>
  _notificationsStreamController =
      StreamController<List<app_notification.Notification>>.broadcast();
  final StreamController<List<FamilyMember>> _familyMembersStreamController =
      StreamController<List<FamilyMember>>.broadcast();

  MockDataService() {
    _userProfiles.forEach(
      (userId, userProfile) => _userProfileStreamController.add(userProfile),
    );
    _userBadges.forEach(
      (userId, badges) => _userBadgesStreamController.add(badges),
    );
    _userAchievements.forEach(
      (userId, achievements) =>
          _userAchievementsStreamController.add(achievements),
    );
    _notifications.forEach(
      (userId, notifications) =>
          _notificationsStreamController.add(notifications),
    );
    _familyMembersStreamController.add(
      _userProfiles.values
          .map((p) => FamilyMember(
            id: p.member.id,
            userId: p.member.userId,
            familyId: p.member.familyId,
            name: p.member.name,
            photoUrl: p.member.photoUrl,
            role: p.member.role,
            points: p.member.points,
            joinedAt: p.member.joinedAt,
            updatedAt: p.member.updatedAt,
          ))
          .toList(),
    );
    logger.i(
      "MockDataService initialized with dummy data for immediate stream emission.",
    );
  }

  // --- User Profile Methods ---
  @override
  Stream<UserProfile?> streamUserProfile({required String userId}) {
    logger.d("Mock: Streaming user profile with ID: $userId.");
    return _userProfileStreamController.stream
        .map((user) => _userProfiles[userId])
        .distinct();
  }

  @override
  Future<UserProfile?> getUserProfile({required String userId}) async {
    logger.d("Mock: Getting user profile with ID: $userId.");
    await Future.delayed(const Duration(milliseconds: 50));
    return _userProfiles[userId];
  }

  @override
  Future<void> createUserProfile({required UserProfile userProfile}) async {
    logger.d("Mock: Creating user profile ${userProfile.id}.");
    _userProfiles[userProfile.id] = userProfile;
    _userProfileStreamController.add(userProfile);
    if (userProfile.familyId != null) {
      _familyMembersStreamController.add(
        _userProfiles.values
            .map((p) => FamilyMember(
              id: p.member.id,
              userId: p.member.userId,
              familyId: p.member.familyId,
              name: p.member.name,
              photoUrl: p.member.photoUrl,
              role: p.member.role,
              points: p.member.points,
              joinedAt: p.member.joinedAt,
              updatedAt: p.member.updatedAt,
            ))
            .toList(),
      );
    }
  }

  @override
  Future<void> updateUserProfile({required UserProfile user}) async {
    logger.d("Mock: Updating user profile ${user.id}.");
    _userProfiles[user.id] = user;
    _userProfileStreamController.add(user);
    if (user.familyId != null) {
      _familyMembersStreamController.add(
        _userProfiles.values
            .map((p) => FamilyMember(
              id: p.member.id,
              userId: p.member.userId,
              familyId: p.member.familyId,
              name: p.member.name,
              photoUrl: p.member.photoUrl,
              role: p.member.role,
              points: p.member.points,
              joinedAt: p.member.joinedAt,
              updatedAt: p.member.updatedAt,
            ))
            .toList(),
      );
    }
  }

  @override
  Future<void> deleteUser({required String userId}) async {
    logger.d("Mock: Deleting user $userId.");
    _userProfiles.remove(userId);
    _userProfileStreamController.add(null);
    _familyMembersStreamController.add(
      _userProfiles.values
          .map((p) => FamilyMember(
            id: p.member.id,
            userId: p.member.userId,
            familyId: p.member.familyId,
            name: p.member.name,
            photoUrl: p.member.photoUrl,
            role: p.member.role,
            points: p.member.points,
            joinedAt: p.member.joinedAt,
            updatedAt: p.member.updatedAt,
          ))
          .toList(),
    );
  }

  @override
  Future<void> updateUserPoints({
    required String userId,
    required int points,
  }) async {
    logger.d("Mock: Updating points for user $userId by $points.");
    final currentUserProfile = _userProfiles[userId];
    if (currentUserProfile != null) {
      _userProfiles[userId] = currentUserProfile.copyWith(
        points: currentUserProfile.points + points,
      );
      _userProfileStreamController.add(_userProfiles[userId]);
    } else {
      logger.w("Mock: User profile $userId not found for points update.");
    }
  }

  // --- Family Methods ---
  @override
  Future<void> createFamily({required Family family}) async {
    logger.d("Mock: Creating family ${family.id}.");
    _families[family.id] = family;
    if (family.memberUserIds.isNotEmpty) {
      _familyMembersStreamController.add(
        _userProfiles.values
            .map((p) => FamilyMember(
              id: p.member.id,
              userId: p.member.userId,
              familyId: p.member.familyId,
              name: p.member.name,
              photoUrl: p.member.photoUrl,
              role: p.member.role,
              points: p.member.points,
              joinedAt: p.member.joinedAt,
              updatedAt: p.member.updatedAt,
            ))
            .toList(),
      );
    }
  }

  @override
  Future<Family?> getFamily({required String familyId}) async {
    logger.d("Mock: Getting family with ID: $familyId.");
    await Future.delayed(const Duration(milliseconds: 50));
    return _families[familyId];
  }

  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    logger.d("Mock: Streaming family members for family ID: $familyId.");
    return _familyMembersStreamController.stream
        .map((members) => members.where((m) => m.familyId == familyId).toList())
        .distinct();
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({
    required String familyId,
  }) async {
    logger.d("Mock: Getting family members for family ID: $familyId.");
    await Future.delayed(const Duration(milliseconds: 50));
    return _userProfiles.values
        .map(
          (profile) =>
              FamilyMember.fromMap(profile.toJson()..['id'] = profile.id),
        )
        .toList();
  }

  // --- Badge Related Methods ---
  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    logger.d("Mock: Streaming badges for user ID: $userId.");
    return _userBadgesStreamController.stream
        .map((badges) => _userBadges[userId] ?? [])
        .distinct();
  }

  @override
  Future<void> awardBadge({
    required String userId,
    required Badge badge,
  }) async {
    logger.d("Mock: Awarding badge ${badge.id} to user $userId.");
    _userBadges.putIfAbsent(userId, () => []).add(badge);
    _userBadgesStreamController.add(_userBadges[userId]!);
  }

  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    logger.d("Mock: Streaming achievements for user ID: $userId.");
    return _userAchievementsStreamController.stream
        .map((achievements) => _userAchievements[userId] ?? [])
        .distinct();
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) async {
    logger.d("Mock: Granting achievement ${achievement.id} to user $userId.");
    _userAchievements.putIfAbsent(userId, () => []).add(achievement);
    _userAchievementsStreamController.add(_userAchievements[userId]!);
  }

  @override
  Stream<List<app_notification.Notification>> streamNotifications({
    required String userId,
  }) {
    logger.d("Mock: Streaming notifications for user ID: $userId.");
    return _notificationsStreamController.stream
        .map((notifications) => _notifications[userId] ?? [])
        .distinct();
  }

  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    logger.d("Mock: Marking notification $notificationId as read.");
    bool updated = false;
    _notifications.forEach((userId, notificationList) {
      final index = notificationList.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notificationList[index] = notificationList[index].copyWith(isRead: true);
        updated = true;
      }
    });
    if (updated) {
      _notifications.forEach((userId, notifications) {
        _notificationsStreamController.add(notifications);
      });
    } else {
      logger.w(
        "Mock: Notification with ID $notificationId not found to mark as read.",
      );
    }
  }

  // --- Task-related methods (mocking DataServiceInterface) ---
  final List<Task> _tasks =
      MockData.tasks
          .map((data) => Task.fromFirestore(data, data['id'] as String))
          .toList();

  @override
  Stream<List<Task>> streamTasks({required String familyId}) {
    return Stream.value(
      _tasks.where((task) => task.familyId == familyId).toList(),
    );
  }

  @override
  Future<Task?> getTask({
    required String familyId,
    required String taskId,
  }) async {
    return _tasks.firstWhereOrNull(
      (task) => task.id == taskId && task.familyId == familyId,
    );
  }

  @override
  Future<void> createTask({
    required String familyId,
    required Task task,
  }) async {
    _tasks.add(task.copyWith(id: 'mock_task_${_tasks.length + 1}'));
  }

  @override
  Future<void> updateTask({
    required String familyId,
    required Task task,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == task.id && t.familyId == familyId,
    );
    if (index != -1) _tasks[index] = task;
  }

  @override
  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) _tasks[index] = _tasks[index].copyWith(status: newStatus);
  }

  @override
  Future<void> assignTask({
    required String familyId,
    required String taskId,
    required String assigneeId,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      // Create a mock FamilyMember for the assignee
      final assignee = FamilyMember(
        id: assigneeId,
        userId: assigneeId,
        familyId: familyId,
        name: 'Mock User $assigneeId',
        photoUrl: null,
        role: FamilyRole.child,
        points: 0,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _tasks[index] = _tasks[index].copyWith(
        assignedTo: assignee,
        status: TaskStatus.assigned,
      );
    }
  }

  @override
  Future<void> deleteTask({
    required String familyId,
    required String taskId,
  }) async {
    _tasks.removeWhere(
      (task) => task.id == taskId && task.familyId == familyId,
    );
  }

  @override
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  }) {
    return Stream.value(
      _tasks
          .where(
            (task) =>
                task.familyId == familyId && task.assigneeId == assigneeId,
          )
          .toList(),
    );
  }

  @override
  Future<void> approveTask({
    required String familyId,
    required String taskId,
    required String approverId,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.completed);
    }
  }

  @override
  Future<void> rejectTask({
    required String familyId,
    required String taskId,
    required String rejecterId,
    String? comments,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(status: TaskStatus.assigned);
    }
  }

  @override
  Future<void> claimTask({
    required String familyId,
    required String taskId,
    required String userId,
  }) async {
    final index = _tasks.indexWhere(
      (t) => t.id == taskId && t.familyId == familyId,
    );
    if (index != -1) {
      // Create a mock FamilyMember for the user
      final user = FamilyMember(
        id: userId,
        userId: userId,
        familyId: familyId,
        name: 'Mock User $userId',
        photoUrl: null,
        role: FamilyRole.child,
        points: 0,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _tasks[index] = _tasks[index].copyWith(
        assignedTo: user,
        status: TaskStatus.assigned,
      );
    }
  }

  void dispose() {
    _userProfileStreamController.close();
    _userBadgesStreamController.close();
    _userAchievementsStreamController.close();
    _notificationsStreamController.close();
    _familyMembersStreamController.close();
    logger.i("MockDataService disposed.");
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
