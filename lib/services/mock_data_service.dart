// lib/services/mock_data_service.dart

import 'dart:async';
import 'dart:math';

import 'package:hoque_family_chores/services/data_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';

/// A mock implementation of the DataService that uses in-memory data
/// for testing and development purposes.
class MockDataService implements DataService {
  // Singleton pattern
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Private state variables
  String? _currentUserId;
  final Map<String, String> _userCredentials = {
    'ahmed@example.com': 'password123',
    'fatima@example.com': 'password123',
    'zahra@example.com': 'password123',
    'yusuf@example.com': 'password123',
    'amina@example.com': 'password123',
  };

  // In-memory data collections (deep copies of MockData to allow modifications)
  final List<Map<String, dynamic>> _userProfiles = List.from(MockData.userProfiles.map((e) => Map<String, dynamic>.from(e)));
  final Map<String, dynamic> _family = Map<String, dynamic>.from(MockData.family);
  final List<Map<String, dynamic>> _tasks = List.from(MockData.tasks.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _badges = List.from(MockData.badges.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _userBadges = List.from(MockData.userBadges.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _achievements = List.from(MockData.achievements.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _userAchievements = List.from(MockData.userAchievements.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _notifications = List.from(MockData.notifications.map((e) => Map<String, dynamic>.from(e)));
  final List<Map<String, dynamic>> _taskHistory = List.from(MockData.taskHistory.map((e) => Map<String, dynamic>.from(e)));
  final Map<String, dynamic> _familyStats = Map<String, dynamic>.from(MockData.familyStats);

  // Helper method to simulate network delay
  Future<void> _simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(700)));
  }

  // Helper method to generate unique IDs
  String _generateId(String prefix) {
    return '${prefix}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  // Helper method to find a user by email
  Map<String, dynamic>? _findUserByEmail(String email) {
    try {
      return _userProfiles.firstWhere((user) => user['email'] == email);
    } catch (e) {
      return null;
    }
  }

  // Helper method to find a user by ID
  Map<String, dynamic>? _findUserById(String userId) {
    try {
      return _userProfiles.firstWhere((user) => user['id'] == userId);
    } catch (e) {
      return null;
    }
  }

  // Authentication Methods
  @override
  Future<String?> signUp({
    required String email, 
    required String password, 
    required String displayName
  }) async {
    await _simulateNetworkDelay();
    
    // Check if user already exists
    if (_findUserByEmail(email) != null) {
      throw Exception('User with this email already exists');
    }
    
    // Create new user
    final userId = _generateId('user');
    _userCredentials[email] = password;
    
    final newUser = {
      'id': userId,
      'displayName': displayName,
      'email': email,
      'photoUrl': null,
      'role': FamilyRole.child.name, // Default role
      'familyId': null,
      'points': 0,
      'level': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'lastActive': DateTime.now().toIso8601String(),
    };
    
    _userProfiles.add(newUser);
    _currentUserId = userId;
    
    return userId;
  }
  
  @override
  Future<String?> signIn({required String email, required String password}) async {
    await _simulateNetworkDelay();
    
    // Check credentials
    if (_userCredentials[email] != password) {
      throw Exception('Invalid email or password');
    }
    
    // Find user
    final user = _findUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Update last active
    final index = _userProfiles.indexWhere((u) => u['id'] == user['id']);
    if (index != -1) {
      _userProfiles[index]['lastActive'] = DateTime.now().toIso8601String();
    }
    
    _currentUserId = user['id'];
    return user['id'];
  }
  
  @override
  Future<void> signOut() async {
    await _simulateNetworkDelay();
    _currentUserId = null;
  }
  
  @override
  Future<void> resetPassword({required String email}) async {
    await _simulateNetworkDelay();
    
    // Check if user exists
    final user = _findUserByEmail(email);
    if (user == null) {
      throw Exception('No user found with this email');
    }
    
    // In a real app, this would send an email
    // Here we just reset the password to a default
    _userCredentials[email] = 'resetPassword123';
  }
  
  @override
  Future<bool> isAuthenticated() async {
    await _simulateNetworkDelay();
    return _currentUserId != null;
  }
  
  @override
  String? getCurrentUserId() {
    return _currentUserId;
  }
  
  // User Management Methods
  @override
  Future<void> createOrUpdateUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? photoUrl,
    FamilyRole? role,
    String? familyId,
    Map<String, Object?>? additionalData
  }) async {
    await _simulateNetworkDelay();
    
    final index = _userProfiles.indexWhere((user) => user['id'] == userId);
    
    if (index != -1) {
      // Update existing user
      _userProfiles[index]['displayName'] = displayName;
      _userProfiles[index]['email'] = email;
      
      if (photoUrl != null) {
        _userProfiles[index]['photoUrl'] = photoUrl;
      }
      
      if (role != null) {
        _userProfiles[index]['role'] = role.name;
      }
      
      if (familyId != null) {
        _userProfiles[index]['familyId'] = familyId;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          _userProfiles[index][key] = value;
        });
      }
    } else {
      // Create new user
      final newUser = {
        'id': userId,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'role': role?.name ?? FamilyRole.child.name,
        'familyId': familyId,
        'points': 0,
        'level': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'lastActive': DateTime.now().toIso8601String(),
      };
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          newUser[key] = value;
        });
      }
      
      _userProfiles.add(newUser);
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getUserProfile({required String userId}) async {
    await _simulateNetworkDelay();
    
    final user = _findUserById(userId);
    if (user == null) {
      return null;
    }
    
    return Map<String, dynamic>.from(user);
  }
  
  @override
  Future<void> deleteUserProfile({required String userId}) async {
    await _simulateNetworkDelay();
    
    _userProfiles.removeWhere((user) => user['id'] == userId);
    
    // Also clean up related data
    _userBadges.removeWhere((badge) => badge['userId'] == userId);
    _userAchievements.removeWhere((achievement) => achievement['userId'] == userId);
    _notifications.removeWhere((notification) => notification['userId'] == userId);
    
    // Update tasks
    for (final task in _tasks) {
      if (task['assigneeId'] == userId) {
        task['assigneeId'] = null;
      }
      
      if (task['isCollaborative'] == true && 
          task['collaborators'] != null && 
          (task['collaborators'] as List).contains(userId)) {
        (task['collaborators'] as List).remove(userId);
      }
    }
  }
  
  // Family Management Methods
  @override
  Future<String> createFamily({
    required String familyName, 
    required String creatorUserId,
    String? familyDescription,
    String? familyPhotoUrl
  }) async {
    await _simulateNetworkDelay();
    
    final familyId = _generateId('family');
    
    final newFamily = {
      'id': familyId,
      'name': familyName,
      'description': familyDescription ?? '',
      'photoUrl': familyPhotoUrl,
      'creatorUserId': creatorUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'memberCount': 1,
      'totalTasksCompleted': 0,
      'totalPoints': 0,
    };
    
    // In a real app with multiple families, we'd add this to a families collection
    // Here we just update our single family
    _family.clear();
    _family.addAll(newFamily);
    
    // Update the creator's profile
    final creatorIndex = _userProfiles.indexWhere((user) => user['id'] == creatorUserId);
    if (creatorIndex != -1) {
      _userProfiles[creatorIndex]['familyId'] = familyId;
      _userProfiles[creatorIndex]['role'] = FamilyRole.parent.name;
    }
    
    return familyId;
  }
  
  @override
  Future<Map<String, dynamic>?> getFamilyDetails({required String familyId}) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] == familyId) {
      return Map<String, dynamic>.from(_family);
    }
    
    return null;
  }
  
  @override
  Future<void> updateFamilyDetails({
    required String familyId,
    String? familyName,
    String? familyDescription,
    String? familyPhotoUrl,
    Map<String, Object?>? additionalData
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] == familyId) {
      if (familyName != null) {
        _family['name'] = familyName;
      }
      
      if (familyDescription != null) {
        _family['description'] = familyDescription;
      }
      
      if (familyPhotoUrl != null) {
        _family['photoUrl'] = familyPhotoUrl;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          _family[key] = value;
        });
      }
    } else {
      throw Exception('Family not found');
    }
  }
  
  @override
  Future<void> addFamilyMember({
    required String familyId, 
    required String userId,
    required FamilyRole role
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    final userIndex = _userProfiles.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      throw Exception('User not found');
    }
    
    _userProfiles[userIndex]['familyId'] = familyId;
    _userProfiles[userIndex]['role'] = role.name;
    
    // Update family member count
    _family['memberCount'] = _userProfiles.where((user) => user['familyId'] == familyId).length;
  }
  
  @override
  Future<void> removeFamilyMember({
    required String familyId, 
    required String userId
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    final userIndex = _userProfiles.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      throw Exception('User not found');
    }
    
    // Can't remove the family creator
    if (_family['creatorUserId'] == userId) {
      throw Exception('Cannot remove the family creator');
    }
    
    _userProfiles[userIndex]['familyId'] = null;
    
    // Update family member count
    _family['memberCount'] = _userProfiles.where((user) => user['familyId'] == familyId).length;
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers({required String familyId}) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    return _userProfiles
        .where((user) => user['familyId'] == familyId)
        .map((user) => Map<String, dynamic>.from(user))
        .toList();
  }
  
  // Task Management Methods
  @override
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
    Map<String, Object?>? additionalData
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    final taskId = _generateId('task');
    final creatorId = _currentUserId;
    
    if (creatorId == null) {
      throw Exception('No authenticated user');
    }
    
    final newTask = {
      'id': taskId,
      'title': title,
      'description': description,
      'familyId': familyId,
      'difficulty': difficulty.name,
      'assigneeId': assigneeId,
      'creatorId': creatorId,
      'status': TaskStatus.pending.name,
      'dueDate': dueDate?.toIso8601String() ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      'categories': categories ?? [],
      'pointValue': pointValue ?? _calculateDefaultPointValue(difficulty),
      'bonusMultiplier': bonusMultiplier ?? 1.0,
      'estimatedMinutes': estimatedMinutes ?? 30,
      'isCollaborative': isCollaborative ?? false,
      'createdAt': DateTime.now().toIso8601String(),
      'subtasks': subtasks ?? [],
    };
    
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        newTask[key] = value;
      });
    }
    
    _tasks.add(newTask);
    
    // Add to task history
    _taskHistory.add({
      'taskId': taskId,
      'action': 'created',
      'timestamp': DateTime.now().toIso8601String(),
      'userId': creatorId,
    });
    
    if (assigneeId != null) {
      _taskHistory.add({
        'taskId': taskId,
        'action': 'assigned',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': creatorId,
        'assigneeId': assigneeId,
      });
      
      // Create notification for assignee
      _notifications.add({
        'id': _generateId('notif'),
        'userId': assigneeId,
        'title': 'New Task Assigned',
        'message': 'You have been assigned to $title',
        'type': 'task_assigned',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'relatedId': taskId,
      });
    }
    
    return taskId;
  }
  
  // Helper method to calculate default point value based on difficulty
  int _calculateDefaultPointValue(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 20;
      case TaskDifficulty.medium:
        return 50;
      case TaskDifficulty.hard:
        return 75;
      case TaskDifficulty.challenging:
        return 100;
    }
    // This line will only be reached if a new enum value is added in the future
    return 50; // Default to medium difficulty points
  }
  
  @override
  Future<Map<String, dynamic>?> getTask({required String taskId}) async {
    await _simulateNetworkDelay();
    
    try {
      final task = _tasks.firstWhere((task) => task['id'] == taskId);
      return Map<String, dynamic>.from(task);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTasksByFamily({
    required String familyId,
    TaskStatus? status,
    String? assigneeId,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  }) async {
    await _simulateNetworkDelay();
    
    var filteredTasks = _tasks.where((task) => task['familyId'] == familyId);
    
    if (status != null) {
      filteredTasks = filteredTasks.where((task) => task['status'] == status.name);
    }
    
    if (assigneeId != null) {
      filteredTasks = filteredTasks.where((task) => task['assigneeId'] == assigneeId);
    }
    
    if (categories != null && categories.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final taskCategories = List<String>.from(task['categories'] ?? []);
        return categories.any((category) => taskCategories.contains(category));
      });
    }
    
    if (startDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        return dueDate.isAfter(startDate) || dueDate.isAtSameMomentAs(startDate);
      });
    }
    
    if (endDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        return dueDate.isBefore(endDate) || dueDate.isAtSameMomentAs(endDate);
      });
    }
    
    var result = filteredTasks.map((task) => Map<String, dynamic>.from(task)).toList();
    
    // Sort by due date (ascending)
    result.sort((a, b) {
      if (a['dueDate'] == null) return 1;
      if (b['dueDate'] == null) return -1;
      return DateTime.parse(a['dueDate']).compareTo(DateTime.parse(b['dueDate']));
    });
    
    if (limit != null && limit > 0 && result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    return result;
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTasksByAssignee({
    required String userId,
    TaskStatus? status,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  }) async {
    await _simulateNetworkDelay();
    
    var filteredTasks = _tasks.where((task) => task['assigneeId'] == userId);
    
    if (status != null) {
      filteredTasks = filteredTasks.where((task) => task['status'] == status.name);
    }
    
    if (categories != null && categories.isNotEmpty) {
      filteredTasks = filteredTasks.where((task) {
        final taskCategories = List<String>.from(task['categories'] ?? []);
        return categories.any((category) => taskCategories.contains(category));
      });
    }
    
    if (startDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        return dueDate.isAfter(startDate) || dueDate.isAtSameMomentAs(startDate);
      });
    }
    
    if (endDate != null) {
      filteredTasks = filteredTasks.where((task) {
        if (task['dueDate'] == null) return false;
        final dueDate = DateTime.parse(task['dueDate']);
        return dueDate.isBefore(endDate) || dueDate.isAtSameMomentAs(endDate);
      });
    }
    
    var result = filteredTasks.map((task) => Map<String, dynamic>.from(task)).toList();
    
    // Sort by due date (ascending)
    result.sort((a, b) {
      if (a['dueDate'] == null) return 1;
      if (b['dueDate'] == null) return -1;
      return DateTime.parse(a['dueDate']).compareTo(DateTime.parse(b['dueDate']));
    });
    
    if (limit != null && limit > 0 && result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    return result;
  }
  
  @override
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
    Map<String, Object?>? additionalData
  }) async {
    await _simulateNetworkDelay();
    
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex == -1) {
      throw Exception('Task not found');
    }
    
    final task = _tasks[taskIndex];
    final oldAssigneeId = task['assigneeId'];
    
    if (title != null) {
      task['title'] = title;
    }
    
    if (description != null) {
      task['description'] = description;
    }
    
    if (assigneeId != null && assigneeId != oldAssigneeId) {
      task['assigneeId'] = assigneeId;
      
      // Add to task history
      _taskHistory.add({
        'taskId': taskId,
        'action': 'reassigned',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
        'oldAssigneeId': oldAssigneeId,
        'newAssigneeId': assigneeId,
      });
      
      // Create notification for new assignee
      _notifications.add({
        'id': _generateId('notif'),
        'userId': assigneeId,
        'title': 'Task Assigned',
        'message': 'You have been assigned to ${task['title']}',
        'type': 'task_assigned',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'relatedId': taskId,
      });
    }
    
    if (status != null) {
      task['status'] = status.name;
      
      // Add to task history
      _taskHistory.add({
        'taskId': taskId,
        'action': 'status_changed',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': _currentUserId,
        'oldStatus': task['status'],
        'newStatus': status.name,
      });
    }
    
    if (difficulty != null) {
      task['difficulty'] = difficulty.name;
      
      // Recalculate point value if not explicitly provided
      if (pointValue == null) {
        task['pointValue'] = _calculateDefaultPointValue(difficulty);
      }
    }
    
    if (dueDate != null) {
      task['dueDate'] = dueDate.toIso8601String();
    }
    
    if (categories != null) {
      task['categories'] = categories;
    }
    
    if (pointValue != null) {
      task['pointValue'] = pointValue;
    }
    
    if (bonusMultiplier != null) {
      task['bonusMultiplier'] = bonusMultiplier;
    }
    
    if (subtasks != null) {
      task['subtasks'] = subtasks;
    }
    
    if (estimatedMinutes != null) {
      task['estimatedMinutes'] = estimatedMinutes;
    }
    
    if (isCollaborative != null) {
      task['isCollaborative'] = isCollaborative;
    }
    
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        task[key] = value;
      });
    }
  }
  
  @override
  Future<void> deleteTask({required String taskId}) async {
    await _simulateNetworkDelay();
    
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex == -1) {
      throw Exception('Task not found');
    }
    
    _tasks.removeAt(taskIndex);
    
    // Remove related task history
    _taskHistory.removeWhere((history) => history['taskId'] == taskId);
    
    // Remove related notifications
    _notifications.removeWhere((notification) => 
        notification['relatedId'] == taskId && 
        notification['type'].toString().startsWith('task_'));
  }
  
  @override
  Future<void> completeTask({
    required String taskId, 
    required String completedByUserId,
    String? completionNotes,
    List<String>? completionPhotoUrls
  }) async {
    await _simulateNetworkDelay();
    
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex == -1) {
      throw Exception('Task not found');
    }
    
    final task = _tasks[taskIndex];
    
    // Check if task is already completed
    if (task['status'] == TaskStatus.completed.name || 
        task['status'] == TaskStatus.verified.name) {
      throw Exception('Task is already completed');
    }
    
    // Check if user is assigned to this task or it's collaborative
    final isAssigned = task['assigneeId'] == completedByUserId;
    final isCollaborative = task['isCollaborative'] == true;
    final isCollaborator = isCollaborative && 
        task['collaborators'] != null && 
        (task['collaborators'] as List).contains(completedByUserId);
    
    if (!isAssigned && !isCollaborator) {
      throw Exception('User is not assigned to this task');
    }
    
    // Update task status
    task['status'] = TaskStatus.completed.name;
    task['completedAt'] = DateTime.now().toIso8601String();
    task['completedByUserId'] = completedByUserId;
    
    if (completionNotes != null) {
      task['completionNotes'] = completionNotes;
    }
    
    if (completionPhotoUrls != null) {
      task['completionPhotoUrls'] = completionPhotoUrls;
    }
    
    // Add to task history
    _taskHistory.add({
      'taskId': taskId,
      'action': 'completed',
      'timestamp': DateTime.now().toIso8601String(),
      'userId': completedByUserId,
      'notes': completionNotes,
    });
    
    // Update family stats
    _familyStats['totalTasksCompleted'] = (_familyStats['totalTasksCompleted'] as int) + 1;
    
    // Create notification for parents
    final parents = _userProfiles.where((user) => 
        user['familyId'] == task['familyId'] && 
        user['role'] == FamilyRole.parent.name);
    
    for (final parent in parents) {
      _notifications.add({
        'id': _generateId('notif'),
        'userId': parent['id'],
        'title': 'Task Completed',
        'message': '${_findUserById(completedByUserId)?['displayName'] ?? 'Someone'} completed the task "${task['title']}"',
        'type': 'task_completed',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
        'relatedId': taskId,
      });
    }
    
    // Award points
    final pointsToAdd = (task['pointValue'] as int) * (task['bonusMultiplier'] as double);
    await updateUserPoints(
      userId: completedByUserId,
      pointsToAdd: pointsToAdd.toInt(),
      reason: 'Completed task: ${task['title']}',
      relatedTaskId: taskId,
    );
    
    // Check for first task completion badge
    final userTasksCompleted = _taskHistory.where((history) => 
        history['action'] == 'completed' && 
        history['userId'] == completedByUserId).length;
    
    if (userTasksCompleted == 1) {
      await awardBadge(
        userId: completedByUserId,
        badgeId: MockData.badgeFirstTask,
        reason: 'Completed first task: ${task['title']}',
      );
    } else if (userTasksCompleted == 10) {
      await awardBadge(
        userId: completedByUserId,
        badgeId: MockData.badgeTaskMaster,
        reason: 'Completed 10 tasks',
      );
    }
  }
  
  @override
  Future<void> verifyTask({
    required String taskId, 
    required String verifiedByUserId,
    String? verificationNotes,
    bool approved = true
  }) async {
    await _simulateNetworkDelay();
    
    final taskIndex = _tasks.indexWhere((task) => task['id'] == taskId);
    if (taskIndex == -1) {
      throw Exception('Task not found');
    }
    
    final task = _tasks[taskIndex];
    
    // Check if task is completed
    if (task['status'] != TaskStatus.completed.name) {
      throw Exception('Task is not completed yet');
    }
    
    // Check if user is a parent
    final verifier = _findUserById(verifiedByUserId);
    if (verifier == null || verifier['role'] != FamilyRole.parent.name) {
      throw Exception('Only parents can verify tasks');
    }
    
    // Update task status
    if (approved) {
      task['status'] = TaskStatus.verified.name;
      task['verifiedAt'] = DateTime.now().toIso8601String();
      task['verifiedByUserId'] = verifiedByUserId;
      
      if (verificationNotes != null) {
        task['verificationNotes'] = verificationNotes;
      }
      
      // Add to task history
      _taskHistory.add({
        'taskId': taskId,
        'action': 'verified',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': verifiedByUserId,
        'notes': verificationNotes,
      });
      
      // Update family stats
      _familyStats['totalTasksVerified'] = (_familyStats['totalTasksVerified'] as int) + 1;
      
      // Create notification for task completer
      final completerId = task['completedByUserId'];
      if (completerId != null) {
        _notifications.add({
          'id': _generateId('notif'),
          'userId': completerId,
          'title': 'Task Verified',
          'message': 'Your task "${task['title']}" has been verified',
          'type': 'task_verified',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'relatedId': taskId,
        });
      }
    } else {
      // If not approved, revert to pending
      task['status'] = TaskStatus.pending.name;
      task.remove('completedAt');
      task.remove('completedByUserId');
      task.remove('completionNotes');
      task.remove('completionPhotoUrls');
      
      // Add to task history
      _taskHistory.add({
        'taskId': taskId,
        'action': 'rejected',
        'timestamp': DateTime.now().toIso8601String(),
        'userId': verifiedByUserId,
        'notes': verificationNotes,
      });
      
      // Create notification for task completer
      final completerId = task['completedByUserId'];
      if (completerId != null) {
        _notifications.add({
          'id': _generateId('notif'),
          'userId': completerId,
          'title': 'Task Rejected',
          'message': 'Your task "${task['title']}" needs more work',
          'type': 'task_rejected',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'relatedId': taskId,
        });
      }
    }
  }
  
  // Gamification Methods
  @override
  Future<void> updateUserPoints({
    required String userId, 
    required int pointsToAdd,
    String? reason,
    String? relatedTaskId
  }) async {
    await _simulateNetworkDelay();
    
    final userIndex = _userProfiles.indexWhere((user) => user['id'] == userId);
    if (userIndex == -1) {
      throw Exception('User not found');
    }
    
    final user = _userProfiles[userIndex];
    final currentPoints = user['points'] as int;
    final newPoints = currentPoints + pointsToAdd;
    
    user['points'] = newPoints;
    
    // Update level based on points
    user['level'] = _calculateLevel(newPoints);
    
    // Update family stats
    final familyId = user['familyId'];
    if (familyId != null && familyId == _family['id']) {
      _familyStats['totalPoints'] = (_familyStats['totalPoints'] as int) + pointsToAdd;
      _familyStats['pointsByUser'][userId] = newPoints;
    }
    
    // Create notification for user
    _notifications.add({
      'id': _generateId('notif'),
      'userId': userId,
      'title': 'Points Earned',
      'message': 'You earned $pointsToAdd points${reason != null ? ' for $reason' : ''}',
      'type': 'points_earned',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
      'relatedId': relatedTaskId,
    });
    
    // Check for level up
    final oldLevel = _calculateLevel(currentPoints);
    final newLevel = _calculateLevel(newPoints);
    
    if (newLevel > oldLevel) {
      _notifications.add({
        'id': _generateId('notif'),
        'userId': userId,
        'title': 'Level Up!',
        'message': 'Congratulations! You reached level $newLevel',
        'type': 'level_up',
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }
  
  // Helper method to calculate level based on points
  int _calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    if (points < 2500) return 6;
    if (points < 4000) return 7;
    if (points < 6000) return 8;
    if (points < 9000) return 9;
    return 10;
  }
  
  @override
  Future<int> getUserPoints({required String userId}) async {
    await _simulateNetworkDelay();
    
    final user = _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    return user['points'] as int;
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFamilyLeaderboard({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    final familyMembers = _userProfiles.where((user) => user['familyId'] == familyId);
    
    // Create leaderboard entries
    final leaderboard = familyMembers.map((user) {
      // Count completed tasks
      final tasksCompleted = _taskHistory.where((history) => 
          history['action'] == 'completed' && 
          history['userId'] == user['id']).length;
      
      return <String, dynamic>{
        'userId': user['id'],
        'displayName': user['displayName'],
        'photoUrl': user['photoUrl'],
        'points': user['points'],
        'level': user['level'],
        'tasksCompleted': tasksCompleted,
        'role': user['role'],
      };
    }).toList();
    
    // Sort by points (descending)
    leaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    
    if (limit != null && limit > 0 && leaderboard.length > limit) {
      return leaderboard.sublist(0, limit);
    }
    
    return leaderboard;
  }
  
  @override
  Future<void> awardBadge({
    required String userId,
    required String badgeId,
    String? reason
  }) async {
    await _simulateNetworkDelay();
    
    // Check if user exists
    final user = _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Check if badge exists
    final badge = _badges.firstWhere(
      (badge) => badge['id'] == badgeId,
      orElse: () => <String, dynamic>{'id': 'unknown', 'name': 'Unknown Badge', 'description': '', 'iconUrl': null, 'pointValue': 0},
    );
    
    // Check if user already has this badge
    final existingBadge = _userBadges.firstWhere(
      (userBadge) => userBadge['userId'] == userId && userBadge['badgeId'] == badgeId,
      orElse: () => <String, dynamic>{},
    );
    
    if (existingBadge.isNotEmpty) {
      // User already has this badge
      return;
    }
    
    // Award badge
    _userBadges.add({
      'userId': userId,
      'badgeId': badgeId,
      'awardedAt': DateTime.now().toIso8601String(),
      'reason': reason,
    });
    
    // Create notification
    _notifications.add({
      'id': _generateId('notif'),
      'userId': userId,
      'title': 'Badge Earned',
      'message': 'You earned the "${badge['name']}" badge',
      'type': 'badge_earned',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
      'relatedId': badgeId,
    });
    
    // Award points for the badge
    final pointsToAdd = badge['pointValue'] as int;
    await updateUserPoints(
      userId: userId,
      pointsToAdd: pointsToAdd,
      reason: 'Earned badge: ${badge['name']}',
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserBadges({required String userId}) async {
    await _simulateNetworkDelay();
    
    // Get user's badges
    final userBadgesList = _userBadges.where((userBadge) => userBadge['userId'] == userId).toList();
    
    // Combine with badge details
    return userBadgesList.map((userBadge) {
      final badgeId = userBadge['badgeId'];
      final badge = _badges.firstWhere(
        (b) => b['id'] == badgeId,
        orElse: () => <String, dynamic>{'name': 'Unknown Badge', 'description': '', 'iconUrl': null},
      );
      
      return <String, dynamic>{
        ...Map<String, dynamic>.from(userBadge),
        'name': badge['name'],
        'description': badge['description'],
        'iconUrl': badge['iconUrl'],
      };
    }).toList();
  }
  
  @override
  Future<void> recordAchievement({
    required String userId,
    required String achievementId,
    int? progressValue,
    bool completed = false
  }) async {
    await _simulateNetworkDelay();
    
    // Check if user exists
    final user = _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Check if achievement exists
    final achievement = _achievements.firstWhere(
      (achievement) => achievement['id'] == achievementId,
      orElse: () => throw Exception('Achievement not found'),
    );
    
    // Find user's progress on this achievement
    final userAchievementIndex = _userAchievements.indexWhere(
      (ua) => ua['userId'] == userId && ua['achievementId'] == achievementId,
    );
    
    if (userAchievementIndex == -1) {
      // User doesn't have this achievement yet, create it
      _userAchievements.add({
        'userId': userId,
        'achievementId': achievementId,
        'currentLevel': 1,
        'currentProgress': progressValue ?? 1,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing achievement progress
      final userAchievement = _userAchievements[userAchievementIndex];
      final currentLevel = userAchievement['currentLevel'] as int;
      final currentProgress = userAchievement['currentProgress'] as int;
      
      // Get achievement levels
      final levels = achievement['levels'] as List;
      final currentLevelData = levels.firstWhere(
        (level) => level['level'] == currentLevel,
        orElse: () => <String, dynamic>{'level': currentLevel, 'requirement': 999999, 'reward': 0},
      );
      
      int newProgress = progressValue ?? currentProgress + 1;
      int newLevel = currentLevel;
      
      // Check if level up
      if (newProgress >= (currentLevelData['requirement'] as int) && currentLevel < levels.length) {
        newLevel = currentLevel + 1;
        
        // Award points for level up
        final reward = currentLevelData['reward'] as int;
        await updateUserPoints(
          userId: userId,
          pointsToAdd: reward,
          reason: 'Achievement level up: ${achievement['name']} Level $currentLevel',
        );
        
        // Create notification for level up
        final newLevelData = levels.firstWhere(
          (level) => level['level'] == newLevel,
          orElse: () => <String, dynamic>{'level': newLevel, 'name': 'Next Level'},
        );
        
        _notifications.add({
          'id': _generateId('notif'),
          'userId': userId,
          'title': 'Achievement Level Up',
          'message': 'You reached ${newLevelData['name']} in ${achievement['name']}',
          'type': 'achievement_level_up',
          'read': false,
          'createdAt': DateTime.now().toIso8601String(),
          'relatedId': achievementId,
        });
      }
      
      // Update the achievement
      _userAchievements[userAchievementIndex] = {
        ...userAchievement,
        'currentLevel': newLevel,
        'currentProgress': newProgress,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserAchievements({required String userId}) async {
    await _simulateNetworkDelay();
    
    // Get user's achievements
    final userAchievementsList = _userAchievements.where((ua) => ua['userId'] == userId).toList();
    
    // Combine with achievement details
    return userAchievementsList.map((userAchievement) {
      final achievementId = userAchievement['achievementId'];
      final achievement = _achievements.firstWhere(
        (a) => a['id'] == achievementId,
        orElse: () => <String, dynamic>{
          'name': 'Unknown Achievement',
          'description': '',
          'levels': [
            {'level': 1, 'requirement': 1, 'reward': 0, 'name': 'Level 1'}
          ]
        },
      );
      
      final currentLevel = userAchievement['currentLevel'] as int;
      final currentProgress = userAchievement['currentProgress'] as int;
      
      final levels = achievement['levels'] as List;
      final currentLevelData = levels.firstWhere(
        (level) => level['level'] == currentLevel,
        orElse: () => <String, dynamic>{'level': currentLevel, 'requirement': 999999, 'reward': 0, 'name': 'Level $currentLevel'},
      );
      
      final nextLevelData = currentLevel < levels.length
          ? levels.firstWhere(
              (level) => level['level'] == currentLevel + 1,
              orElse: () => null,
            )
          : null;
      
      return <String, dynamic>{
        ...Map<String, dynamic>.from(userAchievement),
        'name': achievement['name'],
        'description': achievement['description'],
        'currentLevelName': currentLevelData['name'],
        'currentRequirement': currentLevelData['requirement'],
        'progress': currentProgress,
        'progressPercentage': (currentProgress / (currentLevelData['requirement'] as int) * 100).clamp(0, 100),
        'nextLevel': nextLevelData != null ? nextLevelData['level'] : null,
        'nextLevelName': nextLevelData != null ? nextLevelData['name'] : null,
        'nextRequirement': nextLevelData != null ? nextLevelData['requirement'] : null,
      };
    }).toList();
  }
  
  // Analytics and Reporting Methods
  @override
  Future<Map<String, dynamic>> getTaskCompletionStats({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    // Use the pre-generated stats for now
    return Map<String, dynamic>.from(_familyStats);
  }
  
  @override
  Future<Map<String, dynamic>> getUserActivitySummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    await _simulateNetworkDelay();
    
    final user = _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Count completed tasks
    final completedTasks = _taskHistory.where((history) => 
        history['action'] == 'completed' && 
        history['userId'] == userId).length;
    
    // Get badges count
    final badges = _userBadges.where((badge) => badge['userId'] == userId).length;
    
    // Get highest achievement level
    int highestLevel = 0;
    for (final ua in _userAchievements.where((ua) => ua['userId'] == userId)) {
      final level = ua['currentLevel'] as int;
      if (level > highestLevel) {
        highestLevel = level;
      }
    }
    
    // Generate activity summary
    return <String, dynamic>{
      'userId': userId,
      'displayName': user['displayName'],
      'points': user['points'],
      'level': user['level'],
      'tasksCompleted': completedTasks,
      'badgesEarned': badges,
      'highestAchievementLevel': highestLevel,
      'lastActive': user['lastActive'],
      'memberSince': user['createdAt'],
    };
  }
  
  @override
  Future<Map<String, dynamic>> getFamilyActivitySummary({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    await _simulateNetworkDelay();
    
    if (_family['id'] != familyId) {
      throw Exception('Family not found');
    }
    
    // Use the pre-generated stats
    return Map<String, dynamic>.from(_familyStats);
  }
  
  // Notification Methods
  @override
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String? type,
    Map<String, Object?>? additionalData
  }) async {
    await _simulateNetworkDelay();
    
    final user = _findUserById(userId);
    if (user == null) {
      throw Exception('User not found');
    }
    
    final notification = <String, dynamic>{
      'id': _generateId('notif'),
      'userId': userId,
      'title': title,
      'message': message,
      'type': type ?? 'general',
      'read': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    if (additionalData != null) {
      additionalData.forEach((key, value) {
        notification[key] = value;
      });
    }
    
    _notifications.add(notification);
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool unreadOnly = false,
    int? limit
  }) async {
    await _simulateNetworkDelay();
    
    var filteredNotifications = _notifications.where((notification) => notification['userId'] == userId);
    
    if (unreadOnly) {
      filteredNotifications = filteredNotifications.where((notification) => notification['read'] == false);
    }
    
    var result = filteredNotifications.map((notification) => Map<String, dynamic>.from(notification)).toList();
    
    // Sort by creation date (newest first)
    result.sort((a, b) => 
        DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
    
    if (limit != null && limit > 0 && result.length > limit) {
      result = result.sublist(0, limit);
    }
    
    return result;
  }
  
  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    await _simulateNetworkDelay();
    
    final notificationIndex = _notifications.indexWhere((notification) => notification['id'] == notificationId);
    if (notificationIndex == -1) {
      throw Exception('Notification not found');
    }
    
    _notifications[notificationIndex]['read'] = true;
  }
}
