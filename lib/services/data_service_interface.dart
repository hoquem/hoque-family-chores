import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/models/notification.dart'
    as app_notification;
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/family.dart';

abstract class DataServiceInterface {
  // User Profile methods
  Stream<UserProfile?> streamUserProfile({required String userId});
  Future<UserProfile?> getUserProfile({required String userId});
  Future<void> createUserProfile({required UserProfile userProfile});
  Future<void> updateUserProfile({required UserProfile user});
  Future<void> deleteUser({required String userId});
  Future<void> updateUserPoints({required String userId, required int points});

  // Family methods
  Future<void> createFamily({required Family family});
  Future<Family?> getFamily({required String familyId});
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId});
  Future<List<FamilyMember>> getFamilyMembers({required String familyId});

  // Badge related methods
  Stream<List<Badge>> streamUserBadges({required String userId});
  Future<void> awardBadge({required String userId, required Badge badge});

  // Achievement related methods
  Stream<List<Achievement>> streamUserAchievements({required String userId});
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  });

  // Notification related methods
  Stream<List<app_notification.Notification>> streamNotifications({
    required String userId,
  });
  Future<void> markNotificationAsRead({required String notificationId});

  // Task-related methods
  Stream<List<Task>> streamTasks({required String familyId});
  Future<Task?> getTask({required String familyId, required String taskId});
  Future<void> createTask({required String familyId, required Task task});
  Future<void> updateTask({required String familyId, required Task task});
  Future<void> updateTaskStatus({
    required String familyId,
    required String taskId,
    required TaskStatus newStatus,
  });
  Future<void> assignTask({
    required String familyId,
    required String taskId,
    required String assigneeId,
  });
  Future<void> deleteTask({required String familyId, required String taskId});
  Stream<List<Task>> streamTasksByAssignee({
    required String familyId,
    required String assigneeId,
  });
  Future<void> approveTask({
    required String familyId,
    required String taskId,
    required String approverId,
  });
  Future<void> rejectTask({
    required String familyId,
    required String taskId,
    required String rejecterId,
    String? comments,
  });
  Future<void> claimTask({
    required String familyId,
    required String taskId,
    required String userId,
  });
}
