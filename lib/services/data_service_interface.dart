// lib/services/data_service_interface.dart

import 'package:hoque_family_chores/models/enums.dart';

/// The complete and definitive contract for all data services in the app.
abstract class DataServiceInterface {
  // --- Authentication ---
  Future<String?> signUp({required String email, required String password, required String displayName});
  Future<String?> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> resetPassword({required String email});
  Future<bool> isAuthenticated();
  String? getCurrentUserId();

  // --- User Management ---
  Future<void> createOrUpdateUserProfile({required String userId, required String displayName, required String email, String? photoUrl, FamilyRole? role, String? familyId, Map<String, dynamic>? additionalData});
  Future<Map<String, dynamic>?> getUserProfile({required String userId});
  Future<void> deleteUserProfile({required String userId});

  // --- Family Management ---
  Future<String> createFamily({required String familyName, required String creatorUserId, String? familyDescription, String? familyPhotoUrl});
  Future<Map<String, dynamic>?> getFamilyDetails({required String familyId});
  Future<void> updateFamilyDetails({required String familyId, String? familyName, String? familyDescription, String? familyPhotoUrl, Map<String, dynamic>? additionalData});
  Future<void> addFamilyMember({required String familyId, required String userId, required FamilyRole role});
  Future<void> removeFamilyMember({required String familyId, required String userId});
  Future<List<Map<String, dynamic>>> getFamilyMembers({required String familyId});

  // --- Task Management ---
  Future<String> createTask({required String title, required String description, required String familyId, required TaskDifficulty difficulty, String? assigneeId, DateTime? dueDate, List<String>? categories, int? pointValue, double? bonusMultiplier, List<Map<String, dynamic>>? subtasks, int? estimatedMinutes, bool? isCollaborative, Map<String, dynamic>? additionalData});
  Future<Map<String, dynamic>?> getTask({required String taskId});
  Future<List<Map<String, dynamic>>> getTasksByFamily({required String familyId, TaskStatus? status, String? assigneeId, List<String>? categories, DateTime? startDate, DateTime? endDate, int? limit});
  Stream<List<Map<String, dynamic>>> streamTasksByFamily({required String familyId, TaskStatus? status, String? assigneeId});
  Future<List<Map<String, dynamic>>> getTasksByAssignee({required String userId, TaskStatus? status, List<String>? categories, DateTime? startDate, DateTime? endDate, int? limit});
  Future<void> updateTask({required String taskId, String? title, String? description, String? assigneeId, TaskStatus? status, TaskDifficulty? difficulty, DateTime? dueDate, List<String>? categories, int? pointValue, double? bonusMultiplier, List<Map<String, dynamic>>? subtasks, int? estimatedMinutes, bool? isCollaborative, Map<String, dynamic>? additionalData});
  Future<void> deleteTask({required String taskId});
  Future<void> completeTask({required String taskId, required String completedByUserId, String? completionNotes, List<String>? completionPhotoUrls});
  Future<void> verifyTask({required String taskId, required String verifiedByUserId, String? verificationNotes, bool approved = true});

  // --- Gamification ---
  Future<void> updateUserPoints({required String userId, required int pointsToAdd, String? reason, String? relatedTaskId});
  Future<int> getUserPoints({required String userId});
  Future<List<Map<String, dynamic>>> getFamilyLeaderboard({required String familyId, DateTime? startDate, DateTime? endDate, int? limit});
  Future<void> awardBadge({required String userId, required String badgeId, String? reason});
  Future<List<Map<String, dynamic>>> getUserBadges({required String userId});
  Future<void> recordAchievement({required String userId, required String achievementId, int? progressValue, bool completed = false});
  Future<List<Map<String, dynamic>>> getUserAchievements({required String userId});
  
  // --- Analytics & Reporting ---
  Future<Map<String, dynamic>> getTaskCompletionStats({required String familyId, DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getUserActivitySummary({required String userId, DateTime? startDate, DateTime? endDate});
  Future<Map<String, dynamic>> getFamilyActivitySummary({required String familyId, DateTime? startDate, DateTime? endDate});

  // --- Notifications ---
  Future<void> sendNotification({required String userId, required String title, required String message, String? type, Map<String, dynamic>? additionalData});
  Future<List<Map<String, dynamic>>> getUserNotifications({required String userId, bool unreadOnly = false, int? limit});
  Future<void> markNotificationAsRead({required String notificationId});
}