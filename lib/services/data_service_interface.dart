// lib/services/data_service_interface.dart
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/achievement.dart'; // Ensure this file exists!
import 'package:hoque_family_chores/models/notification.dart' as app_notification; // Ensure this file exists!
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/enums.dart';

abstract class DataServiceInterface {
  // User Profile methods
  Stream<UserProfile?> streamUserProfile({required String userId});
  Future<UserProfile?> getUserProfile({required String userId});
  Future<void> updateUserProfile({required UserProfile user});
  Future<void> deleteUser({required String userId});
  Future<void> updateUserPoints({required String userId, required int points}); // Updated signature

  // Family Member methods
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId});
  Future<List<FamilyMember>> getFamilyMembers({required String familyId}); // Needed by FamilyListScreen

  // Badge related methods
  Stream<List<Badge>> streamUserBadges({required String userId});
  Future<void> awardBadge({required String userId, required Badge badge});

  // Achievement related methods
  Stream<List<Achievement>> streamUserAchievements({required String userId});
  Future<void> grantAchievement({required String userId, required Achievement achievement});

  // Notification related methods
  Stream<List<app_notification.Notification>> streamNotifications({required String userId});
  Future<void> markNotificationAsRead({required String notificationId});

  // --- Task-related methods (as TaskService will delegate to DataService) ---
  Stream<List<Task>> streamTasks({required String familyId}); // Stream all tasks for a family
  Future<Task?> getTask({required String familyId, required String taskId}); // Get a single task
  Future<void> createTask({required String familyId, required Task task}); // From TaskService
  Future<void> updateTask({required String familyId, required Task task}); // Generic update for a task
  Future<void> updateTaskStatus({required String familyId, required String taskId, required TaskStatus newStatus}); // Specific status update
  Future<void> assignTask({required String familyId, required String taskId, required String assigneeId}); // From TaskService
  Future<void> deleteTask({required String familyId, required String taskId}); // From TaskService
  Stream<List<Task>> streamTasksByAssignee({required String familyId, required String assigneeId}); // To support myTasks in providers
}