// lib/services/firebase_data_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/services/data_service.dart';

/// A production implementation of the DataService that connects to Firebase
/// services for authentication, data storage, and retrieval.
class FirebaseDataService implements DataService {
  // Singleton pattern
  static final FirebaseDataService _instance = FirebaseDataService._internal();
  factory FirebaseDataService() => _instance;
  FirebaseDataService._internal();

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _familiesCollection => _firestore.collection('families');
  CollectionReference get _tasksCollection => _firestore.collection('tasks');
  CollectionReference get _badgesCollection => _firestore.collection('badges');
  CollectionReference get _userBadgesCollection => _firestore.collection('user_badges');
  CollectionReference get _achievementsCollection => _firestore.collection('achievements');
  CollectionReference get _userAchievementsCollection => _firestore.collection('user_achievements');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _taskHistoryCollection => _firestore.collection('task_history');
  CollectionReference get _familyStatsCollection => _firestore.collection('family_stats');

  // Helper method to handle Firebase errors
  Never _handleError(dynamic error) {
    debugPrint('Firebase Error: $error');
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          throw Exception('User with this email already exists');
        case 'invalid-email':
          throw Exception('Invalid email address');
        case 'weak-password':
          throw Exception('Password is too weak');
        case 'user-not-found':
        case 'wrong-password':
          throw Exception('Invalid email or password');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        default:
          throw Exception('Authentication error: ${error.message}');
      }
    } else if (error is FirebaseException) {
      throw Exception('Firebase error: ${error.message}');
    } else {
      throw Exception('An unexpected error occurred: $error');
    }
  }

  // Authentication Methods
  @override
  Future<String?> signUp({
    required String email, 
    required String password, 
    required String displayName
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }
      
      // Update display name
      await user.updateDisplayName(displayName);
      
      // Create user profile in Firestore
      await _usersCollection.doc(user.uid).set({
        'displayName': displayName,
        'email': email,
        'photoUrl': null,
        'role': FamilyRole.child.name, // Default role
        'familyId': null,
        'points': 0,
        'level': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      return user.uid;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<String?> signIn({required String email, required String password}) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in');
      }
      
      // Update last active timestamp
      await _usersCollection.doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      return user.uid;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }
  
  @override
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
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
    try {
      // Check if user exists
      final docRef = _usersCollection.doc(userId);
      final docSnapshot = await docRef.get();
      
      final Map<String, dynamic> userData = {
        'displayName': displayName,
        'email': email,
        'lastActive': FieldValue.serverTimestamp(),
      };
      
      if (photoUrl != null) {
        userData['photoUrl'] = photoUrl;
      }
      
      if (role != null) {
        userData['role'] = role.name;
      }
      
      if (familyId != null) {
        userData['familyId'] = familyId;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null) {
            userData[key] = value;
          }
        });
      }
      
      if (docSnapshot.exists) {
        // Update existing user
        await docRef.update(userData);
      } else {
        // Create new user
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['points'] = 0;
        userData['level'] = 1;
        
        await docRef.set(userData);
      }
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getUserProfile({required String userId}) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id;
      
      return data;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> deleteUserProfile({required String userId}) async {
    try {
      // Get user data first
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final familyId = userData['familyId'];
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Delete user profile
      batch.delete(_usersCollection.doc(userId));
      
      // Delete user badges
      final userBadgesQuery = await _userBadgesCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in userBadgesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user achievements
      final userAchievementsQuery = await _userAchievementsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in userAchievementsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete user notifications
      final notificationsQuery = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Update tasks assigned to this user
      final assignedTasksQuery = await _tasksCollection
          .where('assigneeId', isEqualTo: userId)
          .get();
      
      for (final doc in assignedTasksQuery.docs) {
        batch.update(doc.reference, {'assigneeId': null});
      }
      
      // Update collaborative tasks that include this user
      final collaborativeTasksQuery = await _tasksCollection
          .where('isCollaborative', isEqualTo: true)
          .get();
      
      for (final doc in collaborativeTasksQuery.docs) {
        final taskData = doc.data() as Map<String, dynamic>;
        
        if (taskData['collaborators'] != null && 
            (taskData['collaborators'] as List).contains(userId)) {
          final List<dynamic> collaborators = List.from(taskData['collaborators']);
          collaborators.remove(userId);
          
          batch.update(doc.reference, {'collaborators': collaborators});
        }
      }
      
      // If user was in a family, update family member count
      if (familyId != null) {
        final familyDoc = await _familiesCollection.doc(familyId).get();
        
        if (familyDoc.exists) {
          final familyData = familyDoc.data() as Map<String, dynamic>;
          final int currentMemberCount = familyData['memberCount'] ?? 0;
          
          batch.update(_familiesCollection.doc(familyId), {
            'memberCount': currentMemberCount > 0 ? currentMemberCount - 1 : 0,
          });
        }
      }
      
      // Commit the batch
      await batch.commit();
      
      // Delete the Firebase Auth user if this is the current user
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
      }
    } catch (error) {
      _handleError(error);
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
    try {
      // Validate creator user exists
      final creatorDoc = await _usersCollection.doc(creatorUserId).get();
      
      if (!creatorDoc.exists) {
        throw Exception('Creator user not found');
      }
      
      // Create family document
      final familyRef = _familiesCollection.doc();
      
      await familyRef.set({
        'name': familyName,
        'description': familyDescription ?? '',
        'photoUrl': familyPhotoUrl,
        'creatorUserId': creatorUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1,
        'totalTasksCompleted': 0,
        'totalTasksVerified': 0,
        'totalPoints': 0,
      });
      
      final familyId = familyRef.id;
      
      // Update creator's profile
      await _usersCollection.doc(creatorUserId).update({
        'familyId': familyId,
        'role': FamilyRole.parent.name,
      });
      
      // Create initial family stats document
      await _familyStatsCollection.doc(familyId).set({
        'familyId': familyId,
        'totalTasksCreated': 0,
        'totalTasksCompleted': 0,
        'totalTasksVerified': 0,
        'totalPoints': 0,
        'tasksCompletedByCategory': {},
        'tasksCompletedByUser': {},
        'pointsByUser': {
          creatorUserId: 0,
        },
        'weeklyCompletion': [],
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      return familyId;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getFamilyDetails({required String familyId}) async {
    try {
      final docSnapshot = await _familiesCollection.doc(familyId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id;
      
      return data;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> updateFamilyDetails({
    required String familyId,
    String? familyName,
    String? familyDescription,
    String? familyPhotoUrl,
    Map<String, Object?>? additionalData
  }) async {
    try {
      final docRef = _familiesCollection.doc(familyId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        throw Exception('Family not found');
      }
      
      final Map<String, dynamic> updateData = {};
      
      if (familyName != null) {
        updateData['name'] = familyName;
      }
      
      if (familyDescription != null) {
        updateData['description'] = familyDescription;
      }
      
      if (familyPhotoUrl != null) {
        updateData['photoUrl'] = familyPhotoUrl;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null) {
            updateData[key] = value;
          }
        });
      }
      
      if (updateData.isNotEmpty) {
        await docRef.update(updateData);
      }
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> addFamilyMember({
    required String familyId, 
    required String userId,
    required FamilyRole role
  }) async {
    try {
      // Check if family exists
      final familyDoc = await _familiesCollection.doc(familyId).get();
      
      if (!familyDoc.exists) {
        throw Exception('Family not found');
      }
      
      // Check if user exists
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Update user profile
      batch.update(_usersCollection.doc(userId), {
        'familyId': familyId,
        'role': role.name,
      });
      
      // Update family member count
      final familyData = familyDoc.data() as Map<String, dynamic>;
      final int currentMemberCount = familyData['memberCount'] ?? 0;
      
      batch.update(_familiesCollection.doc(familyId), {
        'memberCount': currentMemberCount + 1,
      });
      
      // Update family stats to include this user
      final statsDoc = await _familyStatsCollection.doc(familyId).get();
      
      if (statsDoc.exists) {
        final statsData = statsDoc.data() as Map<String, dynamic>;
        final pointsByUser = Map<String, dynamic>.from(statsData['pointsByUser'] ?? {});
        
        if (!pointsByUser.containsKey(userId)) {
          pointsByUser[userId] = 0;
          batch.update(_familyStatsCollection.doc(familyId), {
            'pointsByUser': pointsByUser,
          });
        }
      }
      
      // Commit the batch
      await batch.commit();
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> removeFamilyMember({
    required String familyId, 
    required String userId
  }) async {
    try {
      // Check if family exists
      final familyDoc = await _familiesCollection.doc(familyId).get();
      
      if (!familyDoc.exists) {
        throw Exception('Family not found');
      }
      
      // Check if user exists
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final familyData = familyDoc.data() as Map<String, dynamic>;
      
      // Can't remove the family creator
      if (familyData['creatorUserId'] == userId) {
        throw Exception('Cannot remove the family creator');
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Update user profile
      batch.update(_usersCollection.doc(userId), {
        'familyId': null,
      });
      
      // Update family member count
      final int currentMemberCount = familyData['memberCount'] ?? 0;
      
      batch.update(_familiesCollection.doc(familyId), {
        'memberCount': currentMemberCount > 0 ? currentMemberCount - 1 : 0,
      });
      
      // Commit the batch
      await batch.commit();
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFamilyMembers({required String familyId}) async {
    try {
      final querySnapshot = await _usersCollection
          .where('familyId', isEqualTo: familyId)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      _handleError(error);
    }
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
    try {
      // Check if family exists
      final familyDoc = await _familiesCollection.doc(familyId).get();
      
      if (!familyDoc.exists) {
        throw Exception('Family not found');
      }
      
      // Check if assignee exists and belongs to the family
      if (assigneeId != null) {
        final assigneeDoc = await _usersCollection.doc(assigneeId).get();
        
        if (!assigneeDoc.exists) {
          throw Exception('Assignee not found');
        }
        
        final assigneeData = assigneeDoc.data() as Map<String, dynamic>;
        
        if (assigneeData['familyId'] != familyId) {
          throw Exception('Assignee does not belong to this family');
        }
      }
      
      final creatorId = _auth.currentUser?.uid;
      
      if (creatorId == null) {
        throw Exception('No authenticated user');
      }
      
      // Create task document
      final taskRef = _tasksCollection.doc();
      
      final Map<String, dynamic> taskData = {
        'title': title,
        'description': description,
        'familyId': familyId,
        'difficulty': difficulty.name,
        'assigneeId': assigneeId,
        'creatorId': creatorId,
        'status': TaskStatus.pending.name,
        'dueDate': dueDate?.toUtc().millisecondsSinceEpoch ?? 
                  DateTime.now().add(const Duration(days: 1)).toUtc().millisecondsSinceEpoch,
        'categories': categories ?? [],
        'pointValue': pointValue ?? _calculateDefaultPointValue(difficulty),
        'bonusMultiplier': bonusMultiplier ?? 1.0,
        'estimatedMinutes': estimatedMinutes ?? 30,
        'isCollaborative': isCollaborative ?? false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      if (subtasks != null && subtasks.isNotEmpty) {
        taskData['subtasks'] = subtasks;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null) {
            taskData[key] = value;
          }
        });
      }
      
      await taskRef.set(taskData);
      
      final taskId = taskRef.id;
      
      // Record task creation in history
      await _taskHistoryCollection.add({
        'taskId': taskId,
        'action': 'created',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': creatorId,
      });
      
      // Update family stats
      final statsDoc = await _familyStatsCollection.doc(familyId).get();
      
      if (statsDoc.exists) {
        final statsData = statsDoc.data() as Map<String, dynamic>;
        final int totalTasksCreated = statsData['totalTasksCreated'] ?? 0;
        
        await _familyStatsCollection.doc(familyId).update({
          'totalTasksCreated': totalTasksCreated + 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      // Create notification for assignee if assigned
      if (assigneeId != null) {
        await _taskHistoryCollection.add({
          'taskId': taskId,
          'action': 'assigned',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': creatorId,
          'assigneeId': assigneeId,
        });
        
        await _notificationsCollection.add({
          'userId': assigneeId,
          'title': 'New Task Assigned',
          'message': 'You have been assigned to $title',
          'type': 'task_assigned',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': taskId,
        });
      }
      
      return taskId;
    } catch (error) {
      _handleError(error);
    }
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
      default:
        return 30;
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getTask({required String taskId}) async {
    try {
      final docSnapshot = await _tasksCollection.doc(taskId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>;
      data['id'] = docSnapshot.id;
      
      // Convert timestamp to ISO string for consistency
      if (data['dueDate'] != null) {
        final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate']);
        data['dueDate'] = dueDate.toIso8601String();
      }
      
      if (data['completedAt'] != null && data['completedAt'] is Timestamp) {
        final completedAt = (data['completedAt'] as Timestamp).toDate();
        data['completedAt'] = completedAt.toIso8601String();
      }
      
      if (data['verifiedAt'] != null && data['verifiedAt'] is Timestamp) {
        final verifiedAt = (data['verifiedAt'] as Timestamp).toDate();
        data['verifiedAt'] = verifiedAt.toIso8601String();
      }
      
      if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        data['createdAt'] = createdAt.toIso8601String();
      }
      
      return data;
    } catch (error) {
      _handleError(error);
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
    try {
      Query query = _tasksCollection.where('familyId', isEqualTo: familyId);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (assigneeId != null) {
        query = query.where('assigneeId', isEqualTo: assigneeId);
      }
      
      // Note: Firestore doesn't support direct array contains any query with multiple values
      // For categories filtering, we'll need to fetch and filter in memory if multiple categories
      
      if (startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: startDate.toUtc().millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: endDate.toUtc().millisecondsSinceEpoch);
      }
      
      // Order by due date
      query = query.orderBy('dueDate', descending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Convert timestamp to ISO string for consistency
        if (data['dueDate'] != null) {
          final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate']);
          data['dueDate'] = dueDate.toIso8601String();
        }
        
        if (data['completedAt'] != null && data['completedAt'] is Timestamp) {
          final completedAt = (data['completedAt'] as Timestamp).toDate();
          data['completedAt'] = completedAt.toIso8601String();
        }
        
        if (data['verifiedAt'] != null && data['verifiedAt'] is Timestamp) {
          final verifiedAt = (data['verifiedAt'] as Timestamp).toDate();
          data['verifiedAt'] = verifiedAt.toIso8601String();
        }
        
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          data['createdAt'] = createdAt.toIso8601String();
        }
        
        return data;
      }).toList();
      
      // Filter by categories if specified (in memory)
      if (categories != null && categories.isNotEmpty) {
        return tasks.where((task) {
          final taskCategories = List<String>.from(task['categories'] ?? []);
          return categories.any((category) => taskCategories.contains(category));
        }).toList();
      }
      
      return tasks;
    } catch (error) {
      _handleError(error);
    }
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
    try {
      Query query = _tasksCollection.where('assigneeId', isEqualTo: userId);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: startDate.toUtc().millisecondsSinceEpoch);
      }
      
      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: endDate.toUtc().millisecondsSinceEpoch);
      }
      
      // Order by due date
      query = query.orderBy('dueDate', descending: false);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Convert timestamp to ISO string for consistency
        if (data['dueDate'] != null) {
          final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate']);
          data['dueDate'] = dueDate.toIso8601String();
        }
        
        if (data['completedAt'] != null && data['completedAt'] is Timestamp) {
          final completedAt = (data['completedAt'] as Timestamp).toDate();
          data['completedAt'] = completedAt.toIso8601String();
        }
        
        if (data['verifiedAt'] != null && data['verifiedAt'] is Timestamp) {
          final verifiedAt = (data['verifiedAt'] as Timestamp).toDate();
          data['verifiedAt'] = verifiedAt.toIso8601String();
        }
        
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          final createdAt = (data['createdAt'] as Timestamp).toDate();
          data['createdAt'] = createdAt.toIso8601String();
        }
        
        return data;
      }).toList();
      
      // Filter by categories if specified (in memory)
      if (categories != null && categories.isNotEmpty) {
        return tasks.where((task) {
          final taskCategories = List<String>.from(task['categories'] ?? []);
          return categories.any((category) => taskCategories.contains(category));
        }).toList();
      }
      
      return tasks;
    } catch (error) {
      _handleError(error);
    }
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
    try {
      final taskDoc = await _tasksCollection.doc(taskId).get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }
      
      final taskData = taskDoc.data() as Map<String, dynamic>;
      final String? oldAssigneeId = taskData['assigneeId'];
      final String familyId = taskData['familyId'];
      
      // Check if assignee exists and belongs to the family
      if (assigneeId != null && assigneeId != oldAssigneeId) {
        final assigneeDoc = await _usersCollection.doc(assigneeId).get();
        
        if (!assigneeDoc.exists) {
          throw Exception('Assignee not found');
        }
        
        final assigneeData = assigneeDoc.data() as Map<String, dynamic>;
        
        if (assigneeData['familyId'] != familyId) {
          throw Exception('Assignee does not belong to this family');
        }
      }
      
      final currentUserId = _auth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('No authenticated user');
      }
      
      final Map<String, dynamic> updateData = {};
      
      if (title != null) {
        updateData['title'] = title;
      }
      
      if (description != null) {
        updateData['description'] = description;
      }
      
      if (assigneeId != null && assigneeId != oldAssigneeId) {
        updateData['assigneeId'] = assigneeId;
        
        // Record reassignment in history
        await _taskHistoryCollection.add({
          'taskId': taskId,
          'action': 'reassigned',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': currentUserId,
          'oldAssigneeId': oldAssigneeId,
          'newAssigneeId': assigneeId,
        });
        
        // Create notification for new assignee
        await _notificationsCollection.add({
          'userId': assigneeId,
          'title': 'Task Assigned',
          'message': 'You have been assigned to ${taskData['title']}',
          'type': 'task_assigned',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': taskId,
        });
      }
      
      if (status != null) {
        updateData['status'] = status.name;
        
        // Record status change in history
        await _taskHistoryCollection.add({
          'taskId': taskId,
          'action': 'status_changed',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': currentUserId,
          'oldStatus': taskData['status'],
          'newStatus': status.name,
        });
      }
      
      if (difficulty != null) {
        updateData['difficulty'] = difficulty.name;
        
        // Recalculate point value if not explicitly provided
        if (pointValue == null) {
          updateData['pointValue'] = _calculateDefaultPointValue(difficulty);
        }
      }
      
      if (dueDate != null) {
        updateData['dueDate'] = dueDate.toUtc().millisecondsSinceEpoch;
      }
      
      if (categories != null) {
        updateData['categories'] = categories;
      }
      
      if (pointValue != null) {
        updateData['pointValue'] = pointValue;
      }
      
      if (bonusMultiplier != null) {
        updateData['bonusMultiplier'] = bonusMultiplier;
      }
      
      if (subtasks != null) {
        updateData['subtasks'] = subtasks;
      }
      
      if (estimatedMinutes != null) {
        updateData['estimatedMinutes'] = estimatedMinutes;
      }
      
      if (isCollaborative != null) {
        updateData['isCollaborative'] = isCollaborative;
      }
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null) {
            updateData[key] = value;
          }
        });
      }
      
      if (updateData.isNotEmpty) {
        await _tasksCollection.doc(taskId).update(updateData);
      }
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> deleteTask({required String taskId}) async {
    try {
      final taskDoc = await _tasksCollection.doc(taskId).get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Delete task
      batch.delete(_tasksCollection.doc(taskId));
      
      // Delete task history
      final historyQuery = await _taskHistoryCollection
          .where('taskId', isEqualTo: taskId)
          .get();
      
      for (final doc in historyQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete task notifications
      final notificationsQuery = await _notificationsCollection
          .where('relatedId', isEqualTo: taskId)
          .where('type', whereIn: ['task_assigned', 'task_completed', 'task_verified', 'task_rejected'])
          .get();
      
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Commit the batch
      await batch.commit();
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> completeTask({
    required String taskId, 
    required String completedByUserId,
    String? completionNotes,
    List<String>? completionPhotoUrls
  }) async {
    try {
      final taskDoc = await _tasksCollection.doc(taskId).get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }
      
      final taskData = taskDoc.data() as Map<String, dynamic>;
      
      // Check if task is already completed
      if (taskData['status'] == TaskStatus.completed.name || 
          taskData['status'] == TaskStatus.verified.name) {
        throw Exception('Task is already completed');
      }
      
      // Check if user is assigned to this task or it's collaborative
      final isAssigned = taskData['assigneeId'] == completedByUserId;
      final isCollaborative = taskData['isCollaborative'] == true;
      final isCollaborator = isCollaborative && 
          taskData['collaborators'] != null && 
          (taskData['collaborators'] as List).contains(completedByUserId);
      
      if (!isAssigned && !isCollaborator) {
        throw Exception('User is not assigned to this task');
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Update task status
      final updateData = {
        'status': TaskStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        'completedByUserId': completedByUserId,
      };
      
      if (completionNotes != null) {
        updateData['completionNotes'] = completionNotes;
      }
      
      if (completionPhotoUrls != null) {
        updateData['completionPhotoUrls'] = completionPhotoUrls;
      }
      
      batch.update(_tasksCollection.doc(taskId), updateData);
      
      // Add to task history
      final historyRef = _taskHistoryCollection.doc();
      batch.set(historyRef, {
        'taskId': taskId,
        'action': 'completed',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': completedByUserId,
        'notes': completionNotes,
      });
      
      // Update family stats
      final familyId = taskData['familyId'];
      final statsDoc = await _familyStatsCollection.doc(familyId).get();
      
      if (statsDoc.exists) {
        final statsData = statsDoc.data() as Map<String, dynamic>;
        
        // Update total tasks completed
        final int totalTasksCompleted = statsData['totalTasksCompleted'] ?? 0;
        
        // Update tasks completed by user
        final tasksCompletedByUser = Map<String, dynamic>.from(statsData['tasksCompletedByUser'] ?? {});
        tasksCompletedByUser[completedByUserId] = (tasksCompletedByUser[completedByUserId] ?? 0) + 1;
        
        // Update tasks completed by category
        final tasksCompletedByCategory = Map<String, dynamic>.from(statsData['tasksCompletedByCategory'] ?? {});
        final List<String> categories = List<String>.from(taskData['categories'] ?? []);
        
        for (final category in categories) {
          tasksCompletedByCategory[category] = (tasksCompletedByCategory[category] ?? 0) + 1;
        }
        
        batch.update(_familyStatsCollection.doc(familyId), {
          'totalTasksCompleted': totalTasksCompleted + 1,
          'tasksCompletedByUser': tasksCompletedByUser,
          'tasksCompletedByCategory': tasksCompletedByCategory,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      // Create notifications for parents
      final parentsQuery = await _usersCollection
          .where('familyId', isEqualTo: familyId)
          .where('role', isEqualTo: FamilyRole.parent.name)
          .get();
      
      final userDoc = await _usersCollection.doc(completedByUserId).get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final String completerName = userData['displayName'] ?? 'Someone';
      
      for (final parentDoc in parentsQuery.docs) {
        final parentId = parentDoc.id;
        
        final notifRef = _notificationsCollection.doc();
        batch.set(notifRef, {
          'userId': parentId,
          'title': 'Task Completed',
          'message': '$completerName completed the task "${taskData['title']}"',
          'type': 'task_completed',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'relatedId': taskId,
        });
      }
      
      // Commit the batch
      await batch.commit();
      
      // Award points
      final pointValue = taskData['pointValue'] as int;
      final bonusMultiplier = taskData['bonusMultiplier'] as double;
      final pointsToAdd = (pointValue * bonusMultiplier).toInt();
      
      await updateUserPoints(
        userId: completedByUserId,
        pointsToAdd: pointsToAdd,
        reason: 'Completed task: ${taskData['title']}',
        relatedTaskId: taskId,
      );
      
      // Check for badges
      // Count completed tasks by this user
      final completedTasksQuery = await _taskHistoryCollection
          .where('userId', isEqualTo: completedByUserId)
          .where('action', isEqualTo: 'completed')
          .get();
      
      final userTasksCompleted = completedTasksQuery.size;
      
      // First task badge
      if (userTasksCompleted == 1) {
        // Find the first task badge
        final firstTaskBadgeQuery = await _badgesCollection
            .where('name', isEqualTo: 'First Task Complete')
            .limit(1)
            .get();
        
        if (firstTaskBadgeQuery.docs.isNotEmpty) {
          final badgeId = firstTaskBadgeQuery.docs.first.id;
          
          await awardBadge(
            userId: completedByUserId,
            badgeId: badgeId,
            reason: 'Completed first task: ${taskData['title']}',
          );
        }
      } 
      // Task master badge (10 tasks)
      else if (userTasksCompleted == 10) {
        // Find the task master badge
        final taskMasterBadgeQuery = await _badgesCollection
            .where('name', isEqualTo: 'Task Master')
            .limit(1)
            .get();
        
        if (taskMasterBadgeQuery.docs.isNotEmpty) {
          final badgeId = taskMasterBadgeQuery.docs.first.id;
          
          await awardBadge(
            userId: completedByUserId,
            badgeId: badgeId,
            reason: 'Completed 10 tasks',
          );
        }
      }
      
      // Update achievements
      // Task streak achievement
      // This would require more complex logic to track daily tasks
      // For now, we'll just update the Super Helper achievement
      
      // Find the Super Helper achievement
      final superHelperQuery = await _achievementsCollection
          .where('name', isEqualTo: 'Super Helper')
          .limit(1)
          .get();
      
      if (superHelperQuery.docs.isNotEmpty) {
        final achievementId = superHelperQuery.docs.first.id;
        
        await recordAchievement(
          userId: completedByUserId,
          achievementId: achievementId,
          progressValue: userTasksCompleted,
        );
      }
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> verifyTask({
    required String taskId, 
    required String verifiedByUserId,
    String? verificationNotes,
    bool approved = true
  }) async {
    try {
      final taskDoc = await _tasksCollection.doc(taskId).get();
      
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }
      
      final taskData = taskDoc.data() as Map<String, dynamic>;
      
      // Check if task is completed
      if (taskData['status'] != TaskStatus.completed.name) {
        throw Exception('Task is not completed yet');
      }
      
      // Check if user is a parent
      final verifierDoc = await _usersCollection.doc(verifiedByUserId).get();
      
      if (!verifierDoc.exists) {
        throw Exception('Verifier not found');
      }
      
      final verifierData = verifierDoc.data() as Map<String, dynamic>;
      
      if (verifierData['role'] != FamilyRole.parent.name) {
        throw Exception('Only parents can verify tasks');
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      if (approved) {
        // Update task status to verified
        final updateData = {
          'status': TaskStatus.verified.name,
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedByUserId': verifiedByUserId,
        };
        
        if (verificationNotes != null) {
          updateData['verificationNotes'] = verificationNotes;
        }
        
        batch.update(_tasksCollection.doc(taskId), updateData);
        
        // Add to task history
        final historyRef = _taskHistoryCollection.doc();
        batch.set(historyRef, {
          'taskId': taskId,
          'action': 'verified',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': verifiedByUserId,
          'notes': verificationNotes,
        });
        
        // Update family stats
        final familyId = taskData['familyId'];
        final statsDoc = await _familyStatsCollection.doc(familyId).get();
        
        if (statsDoc.exists) {
          final statsData = statsDoc.data() as Map<String, dynamic>;
          final int totalTasksVerified = statsData['totalTasksVerified'] ?? 0;
          
          batch.update(_familyStatsCollection.doc(familyId), {
            'totalTasksVerified': totalTasksVerified + 1,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        
        // Create notification for task completer
        final completerId = taskData['completedByUserId'];
        if (completerId != null) {
          final notifRef = _notificationsCollection.doc();
          batch.set(notifRef, {
            'userId': completerId,
            'title': 'Task Verified',
            'message': 'Your task "${taskData['title']}" has been verified',
            'type': 'task_verified',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'relatedId': taskId,
          });
        }
      } else {
        // If not approved, revert to pending
        batch.update(_tasksCollection.doc(taskId), {
          'status': TaskStatus.pending.name,
          'completedAt': FieldValue.delete(),
          'completedByUserId': FieldValue.delete(),
          'completionNotes': FieldValue.delete(),
          'completionPhotoUrls': FieldValue.delete(),
        });
        
        // Add to task history
        final historyRef = _taskHistoryCollection.doc();
        batch.set(historyRef, {
          'taskId': taskId,
          'action': 'rejected',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': verifiedByUserId,
          'notes': verificationNotes,
        });
        
        // Create notification for task completer
        final completerId = taskData['completedByUserId'];
        if (completerId != null) {
          final notifRef = _notificationsCollection.doc();
          batch.set(notifRef, {
            'userId': completerId,
            'title': 'Task Rejected',
            'message': 'Your task "${taskData['title']}" needs more work',
            'type': 'task_rejected',
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
            'relatedId': taskId,
          });
        }
      }
      
      // Commit the batch
      await batch.commit();
    } catch (error) {
      _handleError(error);
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
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final int currentPoints = userData['points'] ?? 0;
      final int newPoints = currentPoints + pointsToAdd;
      
      // Calculate new level
      final int currentLevel = userData['level'] ?? 1;
      final int newLevel = _calculateLevel(newPoints);
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Update user points and level
      batch.update(_usersCollection.doc(userId), {
        'points': newPoints,
        'level': newLevel,
      });
      
      // Update family stats
      final familyId = userData['familyId'];
      if (familyId != null) {
        final statsDoc = await _familyStatsCollection.doc(familyId).get();
        
        if (statsDoc.exists) {
          final statsData = statsDoc.data() as Map<String, dynamic>;
          final int totalPoints = statsData['totalPoints'] ?? 0;
          final pointsByUser = Map<String, dynamic>.from(statsData['pointsByUser'] ?? {});
          
          pointsByUser[userId] = newPoints;
          
          batch.update(_familyStatsCollection.doc(familyId), {
            'totalPoints': totalPoints + pointsToAdd,
            'pointsByUser': pointsByUser,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
      
      // Create notification for points earned
      final notifPointsRef = _notificationsCollection.doc();
      batch.set(notifPointsRef, {
        'userId': userId,
        'title': 'Points Earned',
        'message': 'You earned $pointsToAdd points${reason != null ? ' for $reason' : ''}',
        'type': 'points_earned',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': relatedTaskId,
      });
      
      // Check for level up
      if (newLevel > currentLevel) {
        final notifLevelRef = _notificationsCollection.doc();
        batch.set(notifLevelRef, {
          'userId': userId,
          'title': 'Level Up!',
          'message': 'Congratulations! You reached level $newLevel',
          'type': 'level_up',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      // Commit the batch
      await batch.commit();
    } catch (error) {
      _handleError(error);
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
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('User not found');
      }
      
      final userData = docSnapshot.data() as Map<String, dynamic>;
      return userData['points'] ?? 0;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getFamilyLeaderboard({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit
  }) async {
    try {
      final usersQuery = await _usersCollection
          .where('familyId', isEqualTo: familyId)
          .get();
      
      if (usersQuery.docs.isEmpty) {
        return [];
      }
      
      // Create leaderboard entries
      final leaderboard = await Future.wait(usersQuery.docs.map((doc) async {
        final userData = doc.data() as Map<String, dynamic>;
        final userId = doc.id;
        
        // Count completed tasks
        final tasksCompletedQuery = await _taskHistoryCollection
            .where('userId', isEqualTo: userId)
            .where('action', isEqualTo: 'completed')
            .get();
        
        return {
          'userId': userId,
          'displayName': userData['displayName'] ?? 'Unknown User',
          'photoUrl': userData['photoUrl'],
          'points': userData['points'] ?? 0,
          'level': userData['level'] ?? 1,
          'tasksCompleted': tasksCompletedQuery.size,
          'role': userData['role'] ?? FamilyRole.child.name,
        };
      }));
      
      // Sort by points (descending)
      leaderboard.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
      
      if (limit != null && limit > 0 && leaderboard.length > limit) {
        return leaderboard.sublist(0, limit);
      }
      
      return leaderboard;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> awardBadge({
    required String userId,
    required String badgeId,
    String? reason
  }) async {
    try {
      // Check if user exists
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      // Check if badge exists
      final badgeDoc = await _badgesCollection.doc(badgeId).get();
      
      if (!badgeDoc.exists) {
        throw Exception('Badge not found');
      }
      
      // Check if user already has this badge
      final existingBadgeQuery = await _userBadgesCollection
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .limit(1)
          .get();
      
      if (existingBadgeQuery.docs.isNotEmpty) {
        // User already has this badge
        return;
      }
      
      // Start a batch write
      final batch = _firestore.batch();
      
      // Award badge
      final userBadgeRef = _userBadgesCollection.doc();
      batch.set(userBadgeRef, {
        'userId': userId,
        'badgeId': badgeId,
        'awardedAt': FieldValue.serverTimestamp(),
        'reason': reason,
      });
      
      // Create notification
      final badgeData = badgeDoc.data() as Map<String, dynamic>;
      final badgeName = badgeData['name'] ?? 'Badge';
      
      final notifRef = _notificationsCollection.doc();
      batch.set(notifRef, {
        'userId': userId,
        'title': 'Badge Earned',
        'message': 'You earned the "$badgeName" badge',
        'type': 'badge_earned',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'relatedId': badgeId,
      });
      
      // Commit the batch
      await batch.commit();
      
      // Award points for the badge
      final pointsToAdd = badgeData['pointValue'] as int? ?? 50;
      await updateUserPoints(
        userId: userId,
        pointsToAdd: pointsToAdd,
        reason: 'Earned badge: $badgeName',
      );
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserBadges({required String userId}) async {
    try {
      final userBadgesQuery = await _userBadgesCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return await Future.wait(userBadgesQuery.docs.map((doc) async {
        final userBadgeData = doc.data() as Map<String, dynamic>;
        final badgeId = userBadgeData['badgeId'];
        
        // Get badge details
        final badgeDoc = await _badgesCollection.doc(badgeId).get();
        final badgeData = badgeDoc.exists 
            ? badgeDoc.data() as Map<String, dynamic> 
            : {'name': 'Unknown Badge', 'description': '', 'iconUrl': null};
        
        // Convert timestamp to ISO string
        String? awardedAt;
        if (userBadgeData['awardedAt'] != null && userBadgeData['awardedAt'] is Timestamp) {
          awardedAt = (userBadgeData['awardedAt'] as Timestamp).toDate().toIso8601String();
        }
        
        return {
          'id': doc.id,
          'userId': userBadgeData['userId'],
          'badgeId': badgeId,
          'awardedAt': awardedAt,
          'reason': userBadgeData['reason'],
          'name': badgeData['name'],
          'description': badgeData['description'],
          'iconUrl': badgeData['iconUrl'],
        };
      }));
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> recordAchievement({
    required String userId,
    required String achievementId,
    int? progressValue,
    bool completed = false
  }) async {
    try {
      // Check if user exists
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      // Check if achievement exists
      final achievementDoc = await _achievementsCollection.doc(achievementId).get();
      
      if (!achievementDoc.exists) {
        throw Exception('Achievement not found');
      }
      
      final achievementData = achievementDoc.data() as Map<String, dynamic>;
      
      // Find user's progress on this achievement
      final userAchievementQuery = await _userAchievementsCollection
          .where('userId', isEqualTo: userId)
          .where('achievementId', isEqualTo: achievementId)
          .limit(1)
          .get();
      
      if (userAchievementQuery.docs.isEmpty) {
        // User doesn't have this achievement yet, create it
        await _userAchievementsCollection.add({
          'userId': userId,
          'achievementId': achievementId,
          'currentLevel': 1,
          'currentProgress': progressValue ?? 1,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing achievement progress
        final userAchievementDoc = userAchievementQuery.docs.first;
        final userAchievementData = userAchievementDoc.data() as Map<String, dynamic>;
        
        final int currentLevel = userAchievementData['currentLevel'] ?? 1;
        final int currentProgress = userAchievementData['currentProgress'] ?? 0;
        
        // Get achievement levels
        final levels = achievementData['levels'] as List<dynamic>? ?? [];
        
        Map<String, dynamic>? currentLevelData;
        for (final level in levels) {
          if (level['level'] == currentLevel) {
            currentLevelData = level as Map<String, dynamic>;
            break;
          }
        }
        
        if (currentLevelData == null) {
          currentLevelData = {'level': currentLevel, 'requirement': 999999, 'reward': 0};
        }
        
        int newProgress = progressValue ?? currentProgress + 1;
        int newLevel = currentLevel;
        
        // Check if level up
        if (newProgress >= (currentLevelData['requirement'] as int? ?? 999999) && 
            currentLevel < levels.length) {
          newLevel = currentLevel + 1;
          
          // Award points for level up
          final reward = currentLevelData['reward'] as int? ?? 0;
          await updateUserPoints(
            userId: userId,
            pointsToAdd: reward,
            reason: 'Achievement level up: ${achievementData['name']} Level $currentLevel',
          );
          
          // Create notification for level up
          Map<String, dynamic>? newLevelData;
          for (final level in levels) {
            if (level['level'] == newLevel) {
              newLevelData = level as Map<String, dynamic>;
              break;
            }
          }
          
          if (newLevelData != null) {
            await _notificationsCollection.add({
              'userId': userId,
              'title': 'Achievement Level Up',
              'message': 'You reached ${newLevelData['name']} in ${achievementData['name']}',
              'type': 'achievement_level_up',
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
              'relatedId': achievementId,
            });
          }
        }
        
        // Update the achievement
        await userAchievementDoc.reference.update({
          'currentLevel': newLevel,
          'currentProgress': newProgress,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserAchievements({required String userId}) async {
    try {
      final userAchievementsQuery = await _userAchievementsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      return await Future.wait(userAchievementsQuery.docs.map((doc) async {
        final userAchievementData = doc.data() as Map<String, dynamic>;
        final achievementId = userAchievementData['achievementId'];
        
        // Get achievement details
        final achievementDoc = await _achievementsCollection.doc(achievementId).get();
        
        if (!achievementDoc.exists) {
          return {
            'id': doc.id,
            'userId': userId,
            'achievementId': achievementId,
            'currentLevel': userAchievementData['currentLevel'] ?? 1,
            'currentProgress': userAchievementData['currentProgress'] ?? 0,
            'name': 'Unknown Achievement',
            'description': '',
            'currentLevelName': 'Level ${userAchievementData['currentLevel'] ?? 1}',
            'currentRequirement': 999999,
            'progress': userAchievementData['currentProgress'] ?? 0,
            'progressPercentage': 0,
            'nextLevel': null,
            'nextLevelName': null,
            'nextRequirement': null,
          };
        }
        
        final achievementData = achievementDoc.data() as Map<String, dynamic>;
        final currentLevel = userAchievementData['currentLevel'] as int? ?? 1;
        final currentProgress = userAchievementData['currentProgress'] as int? ?? 0;
        
        final levels = achievementData['levels'] as List<dynamic>? ?? [];
        
        Map<String, dynamic>? currentLevelData;
        for (final level in levels) {
          if (level['level'] == currentLevel) {
            currentLevelData = level as Map<String, dynamic>;
            break;
          }
        }
        
        if (currentLevelData == null) {
          currentLevelData = {
            'level': currentLevel,
            'requirement': 999999,
            'reward': 0,
            'name': 'Level $currentLevel',
          };
        }
        
        Map<String, dynamic>? nextLevelData;
        if (currentLevel < levels.length) {
          for (final level in levels) {
            if (level['level'] == currentLevel + 1) {
              nextLevelData = level as Map<String, dynamic>;
              break;
            }
          }
        }
        
        final requirement = currentLevelData['requirement'] as int? ?? 999999;
        final progressPercentage = requirement > 0 
            ? (currentProgress / requirement * 100).clamp(0, 100) 
            : 0.0;
        
        // Convert timestamp to ISO string
        String? lastUpdated;
        if (userAchievementData['lastUpdated'] != null && 
            userAchievementData['lastUpdated'] is Timestamp) {
          lastUpdated = (userAchievementData['lastUpdated'] as Timestamp)
              .toDate()
              .toIso8601String();
        }
        
        return {
          'id': doc.id,
          'userId': userId,
          'achievementId': achievementId,
          'currentLevel': currentLevel,
          'currentProgress': currentProgress,
          'lastUpdated': lastUpdated,
          'name': achievementData['name'] ?? 'Unknown Achievement',
          'description': achievementData['description'] ?? '',
          'currentLevelName': currentLevelData['name'] ?? 'Level $currentLevel',
          'currentRequirement': requirement,
          'progress': currentProgress,
          'progressPercentage': progressPercentage,
          'nextLevel': nextLevelData != null ? nextLevelData['level'] : null,
          'nextLevelName': nextLevelData != null ? nextLevelData['name'] : null,
          'nextRequirement': nextLevelData != null ? nextLevelData['requirement'] : null,
        };
      }));
    } catch (error) {
      _handleError(error);
    }
  }
  
  // Analytics and Reporting Methods
  @override
  Future<Map<String, dynamic>> getTaskCompletionStats({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    try {
      final statsDoc = await _familyStatsCollection.doc(familyId).get();
      
      if (!statsDoc.exists) {
        throw Exception('Family stats not found');
      }
      
      final statsData = statsDoc.data() as Map<String, dynamic>;
      
      // Convert timestamps to ISO strings
      if (statsData['lastUpdated'] != null && statsData['lastUpdated'] is Timestamp) {
        statsData['lastUpdated'] = (statsData['lastUpdated'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      
      return statsData;
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<Map<String, dynamic>> getUserActivitySummary({
    required String userId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Count completed tasks
      final completedTasksQuery = await _taskHistoryCollection
          .where('userId', isEqualTo: userId)
          .where('action', isEqualTo: 'completed')
          .get();
      
      // Get badges count
      final badgesQuery = await _userBadgesCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      // Get highest achievement level
      final achievementsQuery = await _userAchievementsCollection
          .where('userId', isEqualTo: userId)
          .get();
      
      int highestLevel = 0;
      for (final doc in achievementsQuery.docs) {
        final achievementData = doc.data() as Map<String, dynamic>;
        final level = achievementData['currentLevel'] as int? ?? 0;
        
        if (level > highestLevel) {
          highestLevel = level;
        }
      }
      
      // Convert timestamps to ISO strings
      String? lastActive;
      if (userData['lastActive'] != null && userData['lastActive'] is Timestamp) {
        lastActive = (userData['lastActive'] as Timestamp).toDate().toIso8601String();
      }
      
      String? createdAt;
      if (userData['createdAt'] != null && userData['createdAt'] is Timestamp) {
        createdAt = (userData['createdAt'] as Timestamp).toDate().toIso8601String();
      }
      
      // Generate activity summary
      return {
        'userId': userId,
        'displayName': userData['displayName'] ?? 'Unknown User',
        'points': userData['points'] ?? 0,
        'level': userData['level'] ?? 1,
        'tasksCompleted': completedTasksQuery.size,
        'badgesEarned': badgesQuery.size,
        'highestAchievementLevel': highestLevel,
        'lastActive': lastActive,
        'memberSince': createdAt,
      };
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<Map<String, dynamic>> getFamilyActivitySummary({
    required String familyId,
    DateTime? startDate,
    DateTime? endDate
  }) async {
    try {
      final statsDoc = await _familyStatsCollection.doc(familyId).get();
      
      if (!statsDoc.exists) {
        throw Exception('Family stats not found');
      }
      
      final statsData = statsDoc.data() as Map<String, dynamic>;
      
      // Convert timestamps to ISO strings
      if (statsData['lastUpdated'] != null && statsData['lastUpdated'] is Timestamp) {
        statsData['lastUpdated'] = (statsData['lastUpdated'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      
      return statsData;
    } catch (error) {
      _handleError(error);
    }
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
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final Map<String, dynamic> notificationData = {
        'userId': userId,
        'title': title,
        'message': message,
        'type': type ?? 'general',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          if (value != null) { // Ensure non-null values are assigned
            notificationData[key] = value;
          }
        });
      }
      
      await _notificationsCollection.add(notificationData);
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getUserNotifications({
    required String userId,
    bool unreadOnly = false,
    int? limit
  }) async {
    try {
      Query query = _notificationsCollection
          .where('userId', isEqualTo: userId);
      
      if (unreadOnly) {
        query = query.where('read', isEqualTo: false);
      }
      
      // Order by creation date (newest first)
      query = query.orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // Convert timestamp to ISO string
        if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        
        return data;
      }).toList();
    } catch (error) {
      _handleError(error);
    }
  }
  
  @override
  Future<void> markNotificationAsRead({required String notificationId}) async {
    try {
      final notificationDoc = await _notificationsCollection.doc(notificationId).get();
      
      if (!notificationDoc.exists) {
        throw Exception('Notification not found');
      }
      
      await _notificationsCollection.doc(notificationId).update({
        'read': true,
      });
    } catch (error) {
      _handleError(error);
    }
  }
}
