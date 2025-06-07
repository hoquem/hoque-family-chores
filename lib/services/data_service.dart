// lib/services/data_service.dart

import 'package:flutter/foundation.dart';

/// Models (these would typically be in separate files)
/// Basic models are defined here for reference - in a real implementation,
/// these would be more detailed and in their own files

/// Task status enum
enum TaskStatus { pending, inProgress, completed, verified }

/// Task difficulty level
enum TaskDifficulty { easy, medium, hard, challenging }

/// User role in the family
enum FamilyRole { parent, child, guardian, other }

/// Abstract data service interface that can be implemented by both
/// mock data services and real Firebase services
abstract class DataService {
  /// Authentication Methods
  
  /// Sign up a new user with email and password
  Future<String?> signUp({
    required String email, 
    required String password, 
    required String displayName
  });
  
  /// Sign in an existing user with email and password
  Future<String?> signIn({required String email, required String password});
  
  /// Sign out the current user
  Future<void> signOut();
  
  /// Reset password for a user
  Future<void> resetPassword({required String email});
  
  /// Check if a user is currently authenticated
  Future<bool> isAuthenticated();
  
  /// Get the current user ID
  String? getCurrentUserId();
  
  /// User Management Methods
  
  /// Create or update a user profile
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    FamilyRole? role,
    String? familyId,
    Map<String, dynamic>? additionalData
  });
  
  /// Get a user profile by ID
  Future<Map<String, dynamic>?> getUserProfile({required String userId});
  
  /// Delete a user profile
  Future<void> deleteUserProfile({required String userId});
  
  /// Family Management Methods
  
  /// Create a new family
  Future<String> createFamily({
    required String familyName, 
    required String creatorUserId,
    String? familyDescription,
    String? familyPhotoUrl
  });
  
  /// Get family details
  Future<Map<String, dynamic>?> getFamilyDetails({required String familyId});
  
  /// Update family details
  Future<void> updateFamilyDetails({
    required String familyId,
    String? familyName,
    String? familyDescription,
    String? familyPhotoUrl,
    Map<String, dynamic>? additionalData
  });
  
  /// Add a member to a family
  Future<void> addFamilyMember({
    required String familyId, 
    required String userId,
    required FamilyRole role
  });
  
  /// Remove a member from a family
  Future<void> removeFamilyMember({
    required String familyId, 
    required String userId
  });
  
  /// Get all members of a family
  Future<List<Map<String, dynamic>>> getFamilyMembers({required String familyId});
  
  /// Task Management Methods
  
  /// Create a new task
  Future<String> createTask({
    required String title,
    required String description,
    required String familyId,
    required TaskDifficulty difficulty,
    String? assigneeId,
    DateTime? dueDate,
    List<String>? categories,
    int? pointValue,
    double? bonusMultiplier,
    List<Map<String, dynamic>>? subtasks,
    int? estimatedMinutes,
    bool? isCollaborative,
    Map<String, dynamic>? additionalData
  });
  
  /// Get a task by ID
  Future<Map<String, dynamic>?> getTask({required String taskId});
  
  /// Get tasks by family
  Future<List<Map<String, dynamic>>> getTasksByFamily({
    required String familyId,
    TaskStatus? status,
    String? assigneeId,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  });
  
  /// Get tasks assigned to a specific user
  Future<List<Map<String, dynamic>>> getTasksByAssignee({
    required String userId,
    TaskStatus? status,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  });
  
  /// Update task details
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assigneeId,
    TaskStatus? status,
    TaskDifficulty? difficulty,
    DateTime? dueDate,
    List<String>? categories,
    int? pointValue,
    double? bonusMultiplier,
    List<Map<String, dynamic>>? subtasks,
    int? estimatedMinutes,
    bool? isCollaborative,
    Map<String, dynamic>? additionalData
  });
  
  /// Delete a task
  Future<void> deleteTask({required String taskId});
  
  /// Mark a task as complete
  Future<void> completeTask({
    required String taskId, 
    required String completedByUserId,
    String? completionNotes,
    List<String>? completionPhotoUrls
  });
  
  /// Verify a completed task (typically done by a parent)
  Future<void> verifyTask({
    required String taskId, 
    required String verifiedByUserId,
    String? verificationNotes,
    bool approved = true
  });
  
  /// Gamification Methods
  
  /// Update user points
  Future<void> updateUserPoints({
    required String userId, 
    required int pointsToAdd,
    String? reason,
    String? relatedTaskId
  });
  
  /// Get user points
  Future<int> getUserPoints({required String userId});
  
  /// Get family leaderboard
  Future<List<Map<String, dynamic>>> getFamilyLeaderboard({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  });
  
  /// Award badge to user
  Future<void> awardBadge({
    required String userId,
    required String badgeId,
    String? reason
  });
  
  /// Get user badges
  Future<List<Map<String, dynamic>>> getUserBadges({required String userId});
  
  /// Record achievement for user
  Future<void> recordAchievement({
    required String userId,
    required String achievementId,
    int? progressValue,
    bool completed = false
  });
  
  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements({required String userId});
  
  /// Analytics and Reporting Methods
  
  /// Get task completion statistics
  Future<Map<String, dynamic>> getTaskCompletionStats({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  });
  
  /// Get user activity summary
  Future<Map<String, dynamic>> getUserActivitySummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate
  });
  
  /// Get family activity summary
  Future<Map<String, dynamic>> getFamilyActivitySummary({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  });
  
  /// Notification Methods
  
  /// Send notification to user
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? additionalData
  });
  
  /// Get user notifications
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool unreadOnly = false,
    int? limit
  });
  
  /// Mark notification as read
  Future<void> markNotificationAsRead({required String notificationId});
}
