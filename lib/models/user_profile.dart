// lib/models/user_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';

/// UserProfile extends FamilyMember with gamification data
class UserProfile extends FamilyMember {
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int completedTasks;
  final int currentStreak;
  final int longestStreak;
  final List<Badge> unlockedBadges;
  final List<Reward> redeemedRewards;
  final List<String> achievements;
  final DateTime? lastTaskCompletedAt;
  final DateTime joinedAt;

  /// Base points required to reach level 1
  static const int _basePointsForLevel = 100;
  
  /// Points multiplier for each level
  static const double _levelMultiplier = 1.5;

  UserProfile({
    required super.id,
    required super.name,
    super.avatarUrl,
    super.role,
    this.totalPoints = 0,
    int? currentLevel,
    int? pointsToNextLevel,
    this.completedTasks = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.unlockedBadges = const [],
    this.redeemedRewards = const [],
    this.achievements = const [],
    this.lastTaskCompletedAt,
    required this.joinedAt,
  }) : 
    currentLevel = currentLevel ?? calculateLevelFromPoints(totalPoints),
    pointsToNextLevel = pointsToNextLevel ?? calculatePointsToNextLevel(totalPoints);

  /// Create a copy of this profile with given fields replaced with new values
  UserProfile copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? role,
    int? totalPoints,
    int? currentLevel,
    int? pointsToNextLevel,
    int? completedTasks,
    int? currentStreak,
    int? longestStreak,
    List<Badge>? unlockedBadges,
    List<Reward>? redeemedRewards,
    List<String>? achievements,
    DateTime? lastTaskCompletedAt,
    DateTime? joinedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      completedTasks: completedTasks ?? this.completedTasks,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      redeemedRewards: redeemedRewards ?? this.redeemedRewards,
      achievements: achievements ?? this.achievements,
      lastTaskCompletedAt: lastTaskCompletedAt ?? this.lastTaskCompletedAt,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  /// Calculate level based on total points
  static int calculateLevelFromPoints(int points) {
    if (points < _basePointsForLevel) return 0;
    
    int level = 0;
    double requiredPoints = _basePointsForLevel.toDouble();
    
    while (points >= requiredPoints) {
      level++;
      requiredPoints = _basePointsForLevel * (1 + level * _levelMultiplier);
    }
    
    return level;
  }

  /// Calculate points needed for the next level
  static int calculatePointsToNextLevel(int currentPoints) {
    int currentLevel = calculateLevelFromPoints(currentPoints);
    int nextLevelPoints = (_basePointsForLevel * (1 + currentLevel * _levelMultiplier)).toInt();
    return nextLevelPoints - currentPoints;
  }

  /// Calculate progress percentage to next level (0-100)
  int get levelProgressPercentage {
    if (currentLevel == 0) {
      // For level 0, calculate percentage of base points
      return ((totalPoints / _basePointsForLevel) * 100).toInt();
    }
    
    // For higher levels, calculate based on previous level points and points to next level
    int previousLevelPoints = (_basePointsForLevel * (1 + (currentLevel - 1) * _levelMultiplier)).toInt();
    int nextLevelPoints = (_basePointsForLevel * (1 + currentLevel * _levelMultiplier)).toInt();
    int pointsInCurrentLevel = totalPoints - previousLevelPoints;
    int pointsRequiredForCurrentLevel = nextLevelPoints - previousLevelPoints;
    
    return ((pointsInCurrentLevel / pointsRequiredForCurrentLevel) * 100).toInt();
  }

  /// Check if user has a specific badge
  bool hasBadge(String badgeId) {
    return unlockedBadges.any((badge) => badge.id == badgeId);
  }

  /// Check if user has redeemed a specific reward
  bool hasRedeemedReward(String rewardId) {
    return redeemedRewards.any((reward) => reward.id == rewardId);
  }

  /// Check if user has a specific achievement
  bool hasAchievement(String achievementId) {
    return achievements.contains(achievementId);
  }

  /// Update streak based on task completion
  UserProfile updateStreak() {
    if (lastTaskCompletedAt == null) {
      // First task ever completed
      return copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastTaskCompletedAt: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastCompletionDate = DateTime(
      lastTaskCompletedAt!.year,
      lastTaskCompletedAt!.month,
      lastTaskCompletedAt!.day,
    );
    
    if (lastCompletionDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
      // Already completed a task today, streak unchanged
      return this;
    } else if (lastCompletionDate.isAtSameMomentAs(yesterday)) {
      // Completed a task yesterday, increment streak
      final newStreak = currentStreak + 1;
      return copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
        lastTaskCompletedAt: now,
      );
    } else {
      // Streak broken, reset to 1
      return copyWith(
        currentStreak: 1,
        lastTaskCompletedAt: now,
      );
    }
  }

  /// Add points and update level
  UserProfile addPoints(int points) {
    final newTotalPoints = totalPoints + points;
    final newLevel = calculateLevelFromPoints(newTotalPoints);
    final newPointsToNextLevel = calculatePointsToNextLevel(newTotalPoints);
    
    return copyWith(
      totalPoints: newTotalPoints,
      currentLevel: newLevel,
      pointsToNextLevel: newPointsToNextLevel,
    );
  }

  /// Add a completed task and update stats
  UserProfile completeTask(int taskPoints) {
    final withPoints = addPoints(taskPoints);
    final withStreak = withPoints.updateStreak();
    
    return withStreak.copyWith(
      completedTasks: completedTasks + 1,
    );
  }

  /// Unlock a new badge
  UserProfile unlockBadge(Badge badge) {
    if (hasBadge(badge.id)) return this;
    
    final unlockedBadge = badge.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
    
    return copyWith(
      unlockedBadges: [...unlockedBadges, unlockedBadge],
    );
  }

  /// Redeem a reward
  UserProfile redeemReward(Reward reward) {
    if (totalPoints < reward.pointsCost) {
      throw Exception('Not enough points to redeem this reward');
    }
    
    final redeemedReward = reward.copyWith(
      isRedeemed: true,
      redeemedAt: DateTime.now(),
      redeemedBy: id,
    );
    
    return copyWith(
      totalPoints: totalPoints - reward.pointsCost,
      redeemedRewards: [...redeemedRewards, redeemedReward],
    );
  }

  /// Check for badges that can be unlocked based on current stats
  List<Badge> checkForNewBadges(List<Badge> availableBadges) {
    final newBadges = <Badge>[];
    
    for (final badge in availableBadges) {
      // Skip already unlocked badges
      if (hasBadge(badge.id)) continue;
      
      // Check if user has enough points for this badge
      if (totalPoints >= badge.requiredPoints) {
        // Additional checks based on badge category
        bool shouldUnlock = false;
        
        switch (badge.category) {
          case BadgeCategory.taskMaster:
            shouldUnlock = completedTasks >= _getTaskThresholdForBadge(badge.id);
            break;
          case BadgeCategory.streaker:
            shouldUnlock = currentStreak >= _getStreakThresholdForBadge(badge.id);
            break;
          // Add more category-specific checks as needed
          default:
            shouldUnlock = true;
            break;
        }
        
        if (shouldUnlock) {
          newBadges.add(badge);
        }
      }
    }
    
    return newBadges;
  }
  
  /// Helper method to get task threshold for task master badges
  int _getTaskThresholdForBadge(String badgeId) {
    switch (badgeId) {
      case 'task_master_1': return 5;
      case 'task_master_2': return 15;
      case 'task_master_3': return 30;
      case 'task_master_4': return 50;
      case 'task_master_5': return 100;
      default: return 999999; // Very high number to prevent accidental unlocking
    }
  }
  
  /// Helper method to get streak threshold for streaker badges
  int _getStreakThresholdForBadge(String badgeId) {
    switch (badgeId) {
      case 'streaker_1': return 2;
      case 'streaker_2': return 7;
      case 'streaker_3': return 30;
      default: return 999999; // Very high number to prevent accidental unlocking
    }
  }

  /// Create a UserProfile from a Firestore document
  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Process badges
    List<Badge> badges = [];
    if (data['unlockedBadges'] != null) {
      final badgesList = data['unlockedBadges'] as List<dynamic>;
      badges = badgesList.map((badgeData) {
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
    }
    
    // Process rewards
    List<Reward> rewards = [];
    if (data['redeemedRewards'] != null) {
      final rewardsList = data['redeemedRewards'] as List<dynamic>;
      rewards = rewardsList.map((rewardData) {
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
    }
    
    return UserProfile(
      id: doc.id,
      name: data['name'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      role: data['role'] as String?,
      totalPoints: data['totalPoints'] as int? ?? 0,
      currentLevel: data['currentLevel'] as int?,
      pointsToNextLevel: data['pointsToNextLevel'] as int?,
      completedTasks: data['completedTasks'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      unlockedBadges: badges,
      redeemedRewards: rewards,
      achievements: data['achievements'] != null 
          ? List<String>.from(data['achievements'] as List<dynamic>) 
          : [],
      lastTaskCompletedAt: data['lastTaskCompletedAt'] != null 
          ? (data['lastTaskCompletedAt'] as Timestamp).toDate() 
          : null,
      joinedAt: data['joinedAt'] != null 
          ? (data['joinedAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  /// Convert UserProfile to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'pointsToNextLevel': pointsToNextLevel,
      'completedTasks': completedTasks,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'unlockedBadges': unlockedBadges.map((badge) => badge.toJson()).toList(),
      'redeemedRewards': redeemedRewards.map((reward) => reward.toJson()).toList(),
      'achievements': achievements,
      'lastTaskCompletedAt': lastTaskCompletedAt != null 
          ? Timestamp.fromDate(lastTaskCompletedAt!) 
          : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, role: $role, totalPoints: $totalPoints, level: $currentLevel, completedTasks: $completedTasks, currentStreak: $currentStreak)';
  }
}
