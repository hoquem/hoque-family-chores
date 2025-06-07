// lib/services/gamification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/user_profile.dart';

/// Enum representing different types of gamification events
enum GamificationEventType {
  pointsEarned,
  levelUp,
  badgeUnlocked,
  rewardRedeemed,
  streakIncreased,
  achievementUnlocked,
}

/// Class representing a gamification event
class GamificationEvent {
  final GamificationEventType type;
  final String userId;
  final String message;
  final dynamic data; // Can be points, badge, reward, etc.
  final DateTime timestamp;

  GamificationEvent({
    required this.type,
    required this.userId,
    required this.message,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Interface for gamification services
abstract class GamificationServiceInterface {
  /// Stream of gamification events for real-time updates
  Stream<GamificationEvent> get events;

  /// Get all available badges
  Future<List<Badge>> getAllBadges();

  /// Get badges for a specific user
  Future<List<Badge>> getUserBadges(String userId);

  /// Get all available rewards
  Future<List<Reward>> getAllRewards();

  /// Get rewards redeemed by a specific user
  Future<List<Reward>> getUserRedeemedRewards(String userId);

  /// Get user profile with gamification data
  Future<UserProfile> getUserProfile(String userId);

  /// Award points to a user
  Future<UserProfile> awardPoints(String userId, int points, String reason);

  /// Check for and unlock eligible badges for a user
  Future<List<Badge>> checkAndUnlockBadges(String userId);

  /// Redeem a reward for a user
  Future<bool> redeemReward(String userId, String rewardId);

  /// Handle task completion gamification
  Future<UserProfile> handleTaskCompletion(String userId, Task task);

  /// Check if user has enough points for a reward
  Future<bool> canRedeemReward(String userId, Reward reward);

  /// Get user's current level progress
  Future<Map<String, dynamic>> getLevelProgress(String userId);
}

/// Firebase implementation of GamificationService
class FirebaseGamificationService implements GamificationServiceInterface {
  final FirebaseFirestore _firestore;
  final StreamController<GamificationEvent> _eventsController;

  FirebaseGamificationService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _eventsController = StreamController<GamificationEvent>.broadcast();

  @override
  Stream<GamificationEvent> get events => _eventsController.stream;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection => 
      _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get _badgesCollection => 
      _firestore.collection('badges');
  
  CollectionReference<Map<String, dynamic>> get _rewardsCollection => 
      _firestore.collection('rewards');
  
  CollectionReference<Map<String, dynamic>> get _eventsCollection => 
      _firestore.collection('gamification_events');

  @override
  Future<List<Badge>> getAllBadges() async {
    try {
      final snapshot = await _badgesCollection.get();
      return snapshot.docs
          .map((doc) => Badge.fromSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      // Return predefined badges if Firebase fetch fails
      return Badge.getPredefinedBadges();
    }
  }

  @override
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      if (!userData.containsKey('unlockedBadges')) {
        return [];
      }
      
      final badgesList = userData['unlockedBadges'] as List<dynamic>;
      return badgesList.map((badgeData) {
        return Badge(
          id: badgeData['id'] as String,
          title: badgeData['title'] as String,
          description: badgeData['description'] as String,
          iconName: badgeData['iconName'] as String,
          color: badgeData['color'] as String,
          requiredPoints: badgeData['requiredPoints'] as int,
          category: BadgeCategory.values[badgeData['category'] as int],
          rarity: BadgeRarity.values[badgeData['rarity'] as int],
          isUnlocked: true,
          unlockedAt: badgeData['unlockedAt'] != null 
              ? (badgeData['unlockedAt'] as Timestamp).toDate() 
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user badges: $e');
      return [];
    }
  }

  @override
  Future<List<Reward>> getAllRewards() async {
    try {
      final snapshot = await _rewardsCollection.get();
      return snapshot.docs
          .map((doc) => Reward.fromSnapshot(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching rewards: $e');
      // Return predefined rewards if Firebase fetch fails
      return Reward.getPredefinedRewards();
    }
  }

  @override
  Future<List<Reward>> getUserRedeemedRewards(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      if (!userData.containsKey('redeemedRewards')) {
        return [];
      }
      
      final rewardsList = userData['redeemedRewards'] as List<dynamic>;
      return rewardsList.map((rewardData) {
        return Reward(
          id: rewardData['id'] as String,
          title: rewardData['title'] as String,
          description: rewardData['description'] as String,
          pointsCost: rewardData['pointsCost'] as int,
          iconName: rewardData['iconName'] as String,
          category: RewardCategory.values[rewardData['category'] as int],
          rarity: RewardRarity.values[rewardData['rarity'] as int],
          isRedeemed: true,
          redeemedAt: rewardData['redeemedAt'] != null 
              ? (rewardData['redeemedAt'] as Timestamp).toDate() 
              : null,
          redeemedBy: rewardData['redeemedBy'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user redeemed rewards: $e');
      return [];
    }
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    try {
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User profile not found');
      }
      
      return UserProfile.fromSnapshot(userDoc);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Create a default profile if fetch fails
      return UserProfile(
        id: userId,
        name: 'User',
        joinedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<UserProfile> awardPoints(String userId, int points, String reason) async {
    try {
      // Get current user profile
      final userProfile = await getUserProfile(userId);
      
      // Add points to user profile
      final updatedProfile = userProfile.addPoints(points);
      
      // Check if user leveled up
      final leveledUp = updatedProfile.currentLevel > userProfile.currentLevel;
      
      // Update user profile in Firestore
      await _usersCollection.doc(userId).update({
        'totalPoints': updatedProfile.totalPoints,
        'currentLevel': updatedProfile.currentLevel,
        'pointsToNextLevel': updatedProfile.pointsToNextLevel,
      });
      
      // Emit points earned event
      _emitEvent(GamificationEventType.pointsEarned, userId, 
          'Earned $points points for $reason', points);
      
      // If user leveled up, emit level up event
      if (leveledUp) {
        _emitEvent(GamificationEventType.levelUp, userId, 
            'Leveled up to level ${updatedProfile.currentLevel}!', 
            updatedProfile.currentLevel);
      }
      
      return updatedProfile;
    } catch (e) {
      debugPrint('Error awarding points: $e');
      rethrow;
    }
  }

  @override
  Future<List<Badge>> checkAndUnlockBadges(String userId) async {
    try {
      // Get user profile and all badges
      final userProfile = await getUserProfile(userId);
      final allBadges = await getAllBadges();
      
      // Check for new badges that can be unlocked
      final newBadges = userProfile.checkForNewBadges(allBadges);
      if (newBadges.isEmpty) {
        return [];
      }
      
      // Update user profile with new badges
      UserProfile updatedProfile = userProfile;
      for (final badge in newBadges) {
        updatedProfile = updatedProfile.unlockBadge(badge);
        
        // Emit badge unlocked event
        _emitEvent(GamificationEventType.badgeUnlocked, userId, 
            'Unlocked the "${badge.title}" badge!', badge);
      }
      
      // Update user profile in Firestore
      await _usersCollection.doc(userId).update({
        'unlockedBadges': updatedProfile.unlockedBadges.map((b) => b.toJson()).toList(),
      });
      
      return newBadges;
    } catch (e) {
      debugPrint('Error checking and unlocking badges: $e');
      return [];
    }
  }

  @override
  Future<bool> redeemReward(String userId, String rewardId) async {
    try {
      // Get user profile and reward
      final userProfile = await getUserProfile(userId);
      final allRewards = await getAllRewards();
      final reward = allRewards.firstWhere((r) => r.id == rewardId);
      
      // Check if user has enough points
      if (userProfile.totalPoints < reward.pointsCost) {
        return false;
      }
      
      // Redeem reward
      final updatedProfile = userProfile.redeemReward(reward);
      
      // Update user profile in Firestore
      await _usersCollection.doc(userId).update({
        'totalPoints': updatedProfile.totalPoints,
        'redeemedRewards': updatedProfile.redeemedRewards.map((r) => r.toJson()).toList(),
      });
      
      // Update reward in Firestore if it's a one-time reward
      if (!reward.isAvailable) {
        await _rewardsCollection.doc(rewardId).update({
          'isRedeemed': true,
          'redeemedAt': Timestamp.now(),
          'redeemedBy': userId,
        });
      }
      
      // Emit reward redeemed event
      _emitEvent(GamificationEventType.rewardRedeemed, userId, 
          'Redeemed the "${reward.title}" reward for ${reward.pointsCost} points!', reward);
      
      return true;
    } catch (e) {
      debugPrint('Error redeeming reward: $e');
      return false;
    }
  }

  @override
  Future<UserProfile> handleTaskCompletion(String userId, Task task) async {
    try {
      // Get current user profile
      final userProfile = await getUserProfile(userId);
      
      // Update user profile with completed task
      final updatedProfile = userProfile.completeTask(task.points);
      
      // Check if streak increased
      final streakIncreased = updatedProfile.currentStreak > userProfile.currentStreak;
      
      // Update user profile in Firestore
      await _usersCollection.doc(userId).update({
        'totalPoints': updatedProfile.totalPoints,
        'currentLevel': updatedProfile.currentLevel,
        'pointsToNextLevel': updatedProfile.pointsToNextLevel,
        'completedTasks': updatedProfile.completedTasks,
        'currentStreak': updatedProfile.currentStreak,
        'longestStreak': updatedProfile.longestStreak,
        'lastTaskCompletedAt': Timestamp.fromDate(updatedProfile.lastTaskCompletedAt ?? DateTime.now()),
      });
      
      // Emit points earned event
      _emitEvent(GamificationEventType.pointsEarned, userId, 
          'Earned ${task.points} points for completing "${task.title}"', task.points);
      
      // If streak increased, emit streak event
      if (streakIncreased) {
        _emitEvent(GamificationEventType.streakIncreased, userId, 
            'Streak increased to ${updatedProfile.currentStreak} days!', 
            updatedProfile.currentStreak);
      }
      
      // Check for new badges
      await checkAndUnlockBadges(userId);
      
      return updatedProfile;
    } catch (e) {
      debugPrint('Error handling task completion: $e');
      rethrow;
    }
  }

  @override
  Future<bool> canRedeemReward(String userId, Reward reward) async {
    try {
      final userProfile = await getUserProfile(userId);
      return userProfile.totalPoints >= reward.pointsCost;
    } catch (e) {
      debugPrint('Error checking if user can redeem reward: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getLevelProgress(String userId) async {
    try {
      final userProfile = await getUserProfile(userId);
      
      return {
        'currentLevel': userProfile.currentLevel,
        'totalPoints': userProfile.totalPoints,
        'pointsToNextLevel': userProfile.pointsToNextLevel,
        'progressPercentage': userProfile.levelProgressPercentage,
      };
    } catch (e) {
      debugPrint('Error getting level progress: $e');
      return {
        'currentLevel': 0,
        'totalPoints': 0,
        'pointsToNextLevel': 100,
        'progressPercentage': 0,
      };
    }
  }

  /// Helper method to emit gamification events
  void _emitEvent(GamificationEventType type, String userId, String message, dynamic data) {
    final event = GamificationEvent(
      type: type,
      userId: userId,
      message: message,
      data: data,
    );
    
    // Add event to Firestore for history
    _eventsCollection.add({
      'type': type.index,
      'userId': userId,
      'message': message,
      'data': data is Badge || data is Reward ? data.toJson() : data,
      'timestamp': Timestamp.now(),
    });
    
    // Emit event to stream
    _eventsController.add(event);
  }
  
  /// Initialize the gamification system by ensuring all predefined badges and rewards exist
  Future<void> initializeSystem() async {
    try {
      // Check if badges collection exists and has data
      final badgesSnapshot = await _badgesCollection.limit(1).get();
      if (badgesSnapshot.docs.isEmpty) {
        // Add predefined badges
        final badges = Badge.getPredefinedBadges();
        for (final badge in badges) {
          await _badgesCollection.doc(badge.id).set(badge.toJson());
        }
        debugPrint('Initialized ${badges.length} predefined badges');
      }
      
      // Check if rewards collection exists and has data
      final rewardsSnapshot = await _rewardsCollection.limit(1).get();
      if (rewardsSnapshot.docs.isEmpty) {
        // Add predefined rewards
        final rewards = Reward.getPredefinedRewards();
        for (final reward in rewards) {
          await _rewardsCollection.doc(reward.id).set(reward.toJson());
        }
        debugPrint('Initialized ${rewards.length} predefined rewards');
      }
    } catch (e) {
      debugPrint('Error initializing gamification system: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _eventsController.close();
  }
}

/// Mock implementation of GamificationService for testing
class MockGamificationService implements GamificationServiceInterface {
  final StreamController<GamificationEvent> _eventsController;
  final Map<String, UserProfile> _userProfiles = {};
  final List<Badge> _badges = Badge.getPredefinedBadges();
  final List<Reward> _rewards = Reward.getPredefinedRewards();
  
  MockGamificationService() 
      : _eventsController = StreamController<GamificationEvent>.broadcast();
  
  @override
  Stream<GamificationEvent> get events => _eventsController.stream;

  @override
  Future<List<Badge>> getAllBadges() async {
    return _badges;
  }

  @override
  Future<List<Badge>> getUserBadges(String userId) async {
    final profile = await _getOrCreateUserProfile(userId);
    return profile.unlockedBadges;
  }

  @override
  Future<List<Reward>> getAllRewards() async {
    return _rewards;
  }

  @override
  Future<List<Reward>> getUserRedeemedRewards(String userId) async {
    final profile = await _getOrCreateUserProfile(userId);
    return profile.redeemedRewards;
  }

  @override
  Future<UserProfile> getUserProfile(String userId) async {
    return _getOrCreateUserProfile(userId);
  }

  @override
  Future<UserProfile> awardPoints(String userId, int points, String reason) async {
    final profile = await _getOrCreateUserProfile(userId);
    final oldLevel = profile.currentLevel;
    
    final updatedProfile = profile.addPoints(points);
    _userProfiles[userId] = updatedProfile;
    
    // Emit points earned event
    _emitEvent(GamificationEventType.pointsEarned, userId, 
        'Earned $points points for $reason', points);
    
    // If user leveled up, emit level up event
    if (updatedProfile.currentLevel > oldLevel) {
      _emitEvent(GamificationEventType.levelUp, userId, 
          'Leveled up to level ${updatedProfile.currentLevel}!', 
          updatedProfile.currentLevel);
    }
    
    return updatedProfile;
  }

  @override
  Future<List<Badge>> checkAndUnlockBadges(String userId) async {
    final profile = await _getOrCreateUserProfile(userId);
    final newBadges = profile.checkForNewBadges(_badges);
    
    if (newBadges.isEmpty) {
      return [];
    }
    
    // Update user profile with new badges
    UserProfile updatedProfile = profile;
    for (final badge in newBadges) {
      updatedProfile = updatedProfile.unlockBadge(badge);
      
      // Emit badge unlocked event
      _emitEvent(GamificationEventType.badgeUnlocked, userId, 
          'Unlocked the "${badge.title}" badge!', badge);
    }
    
    _userProfiles[userId] = updatedProfile;
    return newBadges;
  }

  @override
  Future<bool> redeemReward(String userId, String rewardId) async {
    final profile = await _getOrCreateUserProfile(userId);
    final reward = _rewards.firstWhere((r) => r.id == rewardId);
    
    if (profile.totalPoints < reward.pointsCost) {
      return false;
    }
    
    try {
      final updatedProfile = profile.redeemReward(reward);
      _userProfiles[userId] = updatedProfile;
      
      // Emit reward redeemed event
      _emitEvent(GamificationEventType.rewardRedeemed, userId, 
          'Redeemed the "${reward.title}" reward for ${reward.pointsCost} points!', reward);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<UserProfile> handleTaskCompletion(String userId, Task task) async {
    final profile = await _getOrCreateUserProfile(userId);
    final oldStreak = profile.currentStreak;
    
    final updatedProfile = profile.completeTask(task.points);
    _userProfiles[userId] = updatedProfile;
    
    // Emit points earned event
    _emitEvent(GamificationEventType.pointsEarned, userId, 
        'Earned ${task.points} points for completing "${task.title}"', task.points);
    
    // If streak increased, emit streak event
    if (updatedProfile.currentStreak > oldStreak) {
      _emitEvent(GamificationEventType.streakIncreased, userId, 
          'Streak increased to ${updatedProfile.currentStreak} days!', 
          updatedProfile.currentStreak);
    }
    
    // Check for new badges
    await checkAndUnlockBadges(userId);
    
    return updatedProfile;
  }

  @override
  Future<bool> canRedeemReward(String userId, Reward reward) async {
    final profile = await _getOrCreateUserProfile(userId);
    return profile.totalPoints >= reward.pointsCost;
  }

  @override
  Future<Map<String, dynamic>> getLevelProgress(String userId) async {
    final profile = await _getOrCreateUserProfile(userId);
    
    return {
      'currentLevel': profile.currentLevel,
      'totalPoints': profile.totalPoints,
      'pointsToNextLevel': profile.pointsToNextLevel,
      'progressPercentage': profile.levelProgressPercentage,
    };
  }

  /// Helper method to get or create a user profile
  Future<UserProfile> _getOrCreateUserProfile(String userId) async {
    if (!_userProfiles.containsKey(userId)) {
      _userProfiles[userId] = UserProfile(
        id: userId,
        name: 'User $userId',
        joinedAt: DateTime.now(),
      );
    }
    return _userProfiles[userId]!;
  }

  /// Helper method to emit gamification events
  void _emitEvent(GamificationEventType type, String userId, String message, dynamic data) {
    final event = GamificationEvent(
      type: type,
      userId: userId,
      message: message,
      data: data,
    );
    
    _eventsController.add(event);
  }
  
  /// Dispose resources
  void dispose() {
    _eventsController.close();
  }
}
