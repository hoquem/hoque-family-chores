// lib/services/mock_data_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';
import 'package:uuid/uuid.dart';

/// A stateful mock implementation of the DataService that uses in-memory data.
/// This class implements the entire DataServiceInterface for development and testing.
class MockDataService implements DataServiceInterface {
  // Singleton pattern for a single instance throughout the app's lifecycle.
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal() {
    // When the service is created, immediately push the initial task list
    // to the stream for any early listeners.
    _tasksStreamController.add(_tasks);
  }

  // --- State Management ---
  String? _currentUserId = MockData.childUserId1; // Default login for easy testing
  final _tasksStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // In-memory data collections (deep copies of MockData to allow modifications)
  final List<Map<String, dynamic>> _userProfiles = List.from(MockData.userProfiles.map((e) => Map.from(e)));
  final List<Map<String, dynamic>> _tasks = List.from(MockData.tasks.map((e) => Map.from(e)));

  // --- Helpers ---
  Future<void> _simulateNetworkDelay() async => await Future.delayed(const Duration(milliseconds: 300));
  String _generateId(String prefix) => '${prefix}_${const Uuid().v4()}';

  // --- AUTHENTICATION ---
  @override
  Future<String?> signUp({required String email, required String password, required String displayName}) async {
    await _simulateNetworkDelay();
    if (_userProfiles.any((p) => p['email'] == email)) {
      throw Exception('Email already in use.');
    }
    final userId = _generateId('user');
    final newUser = {
      'id': userId, 'displayName': displayName, 'email': email,
      'role': FamilyRole.child.name, 'points': 0, 'level': 1
    };
    _userProfiles.add(newUser);
    _currentUserId = userId;
    return userId;
  }

  @override
  Future<String?> signIn({required String email, required String password}) async {
    await _simulateNetworkDelay();
    final user = _userProfiles.firstWhere((u) => u['email'] == email, orElse: () => {});
    if (user.isNotEmpty) {
      _currentUserId = user['id'];
      return _currentUserId;
    }
    throw Exception('User not found with that email.');
  }

  @override
  Future<void> signOut() async {
    await _simulateNetworkDelay();
    _currentUserId = null;
  }

  // ADDED: Missing concrete implementation for resetPassword
  @override
  Future<void> resetPassword({required String email}) async {
    await _simulateNetworkDelay();
    debugPrint("Password reset email sent to $email (mock behavior).");
    return;
  }
  
  @override
  String? getCurrentUserId() => _currentUserId;
  
  @override
  Future<bool> isAuthenticated() async => _currentUserId != null;

  // --- TASK MANAGEMENT ---
  @override
  Future<String> createTask({
    required String title, required String description, required String familyId,
    required TaskDifficulty difficulty, String? assigneeId, DateTime? dueDate,
    List<String>? categories, int? pointValue, double? bonusMultiplier,
    List<Map<String, dynamic>>? subtasks, int? estimatedMinutes, bool? isCollaborative,
    Map<String, dynamic>? additionalData,
  }) async {
    await _simulateNetworkDelay();
    final taskId = _generateId('task');
    final newTask = {
      'id': taskId, 'title': title, 'description': description, 'familyId': familyId,
      'difficulty': difficulty.name, 'pointValue': pointValue ?? 50,
      'status': TaskStatus.pending.name, 'createdAt': DateTime.now().toIso8601String(),
      'assigneeId': assigneeId, 'assigneeName': assigneeId != null ? _userProfiles.firstWhere((p) => p['id'] == assigneeId)['displayName'] : null,
      'dueDate': dueDate?.toIso8601String(),
    };
    _tasks.insert(0, newTask);
    _tasksStreamController.add(List.from(_tasks));
    return taskId;
  }

  @override
  Stream<List<Map<String, dynamic>>> streamTasksByFamily({
    required String familyId, TaskStatus? status, String? assigneeId,
  }) {
    return _tasksStreamController.stream.map((allTasks) {
      var filtered = allTasks.where((task) => task['familyId'] == familyId);
      if (status != null) filtered = filtered.where((task) => task['status'] == status.name);
      if (assigneeId != null) filtered = filtered.where((task) => task['assigneeId'] == assigneeId);
      return filtered.toList();
    });
  }
  
  // MODIFIED: Signature now correctly matches the interface with all parameters
  @override
  Future<void> updateTask({
    required String taskId, String? title, String? description,
    String? assigneeId, TaskStatus? status, TaskDifficulty? difficulty,
    DateTime? dueDate, List<String>? categories, int? pointValue,
    double? bonusMultiplier, List<Map<String, dynamic>>? subtasks,
    int? estimatedMinutes, bool? isCollaborative, Map<String, dynamic>? additionalData,
  }) async {
    await _simulateNetworkDelay();
    final taskIndex = _tasks.indexWhere((t) => t['id'] == taskId);
    if(taskIndex != -1) {
      if(title != null) _tasks[taskIndex]['title'] = title;
      if(description != null) _tasks[taskIndex]['description'] = description;
      if(status != null) _tasks[taskIndex]['status'] = status.name;
      if(assigneeId != null) {
         _tasks[taskIndex]['assigneeId'] = assigneeId;
         _tasks[taskIndex]['assigneeName'] = _userProfiles.firstWhere((p) => p['id'] == assigneeId)['displayName'];
      }
      if(dueDate != null) _tasks[taskIndex]['dueDate'] = dueDate.toIso8601String();
      _tasksStreamController.add(List.from(_tasks));
    }
  }

  // ADDED: Complete implementation for deleteUserProfile
  @override
  Future<void> deleteUserProfile({required String userId}) async {
    await _simulateNetworkDelay();
    // Remove the user profile from the list
    _userProfiles.removeWhere((profile) => profile['id'] == userId);

    // Unassign any tasks that were assigned to the deleted user
    for (final task in _tasks) {
      if (task['assigneeId'] == userId) {
        task['assigneeId'] = null;
        task['assigneeName'] = null;
      }
    }
    // Push the updated task list to the stream so the UI reflects the change
    _tasksStreamController.add(List.from(_tasks));
    
    // If the deleted user was the currently logged-in user, sign them out
    if (_currentUserId == userId) {
      _currentUserId = null;
    }
  }


  // --- All other methods from the interface (with placeholder implementations) ---
  @override
  Future<List<Map<String, dynamic>>> getFamilyLeaderboard({required String familyId, DateTime? startDate, DateTime? endDate, int? limit}) async { return []; }
  @override
  Future<Map<String, dynamic>> getFamilyActivitySummary({required String familyId, DateTime? startDate, DateTime? endDate}) async { return {}; }
  @override
  Future<Map<String, dynamic>?> getFamilyDetails({required String familyId}) async { return null; }
  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers({required String familyId}) async { return []; }
  @override
  Future<Map<String, dynamic>?> getTask({required String taskId}) async { return null; }
  @override
  Future<Map<String, dynamic>> getTaskCompletionStats({required String familyId, DateTime? startDate, DateTime? endDate}) async { return {}; }
  @override
  Future<List<Map<String, dynamic>>> getTasksByAssignee({required String userId, TaskStatus? status, List<String>? categories, DateTime? startDate, DateTime? endDate, int? limit}) async { return []; }
  @override
  Future<List<Map<String, dynamic>>> getTasksByFamily({required String familyId, TaskStatus? status, String? assigneeId, List<String>? categories, DateTime? startDate, DateTime? endDate, int? limit}) async { return []; }
  @override
  Future<List<Map<String, dynamic>>> getUserAchievements({required String userId}) async { return []; }
  @override
  Future<Map<String, dynamic>> getUserActivitySummary({required String userId, DateTime? startDate, DateTime? endDate}) async { return {}; }
  @override
  Future<List<Map<String, dynamic>>> getUserBadges({required String userId}) async { return []; }
  @override
  Future<List<Map<String, dynamic>>> getUserNotifications({required String userId, bool unreadOnly = false, int? limit}) async { return []; }
  @override
  Future<int> getUserPoints({required String userId}) async { return 0; }
  @override
  Future<Map<String, dynamic>?> getUserProfile({required String userId}) async {
    await _simulateNetworkDelay();
    try {
      return _userProfiles.firstWhere((p) => p['id'] == userId);
    } catch (e) {
      return null;
    }
  }
  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {}
  @override
  Future<void> recordAchievement({required String userId, required String achievementId, int? progressValue, bool completed = false}) async {}
  @override
  Future<void> removeFamilyMember({required String familyId, required String userId}) async {}
  @override
  Future<void> sendNotification({required String userId, required String title, required String message, String? type, Map<String, dynamic>? additionalData}) async {}
  @override
  Future<void> updateUserPoints({required String userId, required int pointsToAdd, String? reason, String? relatedTaskId}) async {}
  @override
  Future<void> verifyTask({required String taskId, required String verifiedByUserId, String? verificationNotes, bool approved = true}) async {}
  @override
  Future<void> addFamilyMember({required String familyId, required String userId, required FamilyRole role}) async {}
  @override
  Future<void> awardBadge({required String userId, required String badgeId, String? reason}) async {}
  @override
  Future<void> completeTask({required String taskId, required String completedByUserId, String? completionNotes, List<String>? completionPhotoUrls}) async {}
  @override
  Future<String> createFamily({required String familyName, required String creatorUserId, String? familyDescription, String? familyPhotoUrl}) async { return ''; }
  @override
  Future<void> createOrUpdateUserProfile({required String userId, required String displayName, required String email, String? photoUrl, FamilyRole? role, String? familyId, Map<String, dynamic>? additionalData}) async {}
  @override
  Future<void> deleteTask({required String taskId}) async {}
  @override
  Future<void> updateFamilyDetails({required String familyId, String? familyName, String? familyDescription, String? familyPhotoUrl, Map<String, dynamic>? additionalData}) async {}
}