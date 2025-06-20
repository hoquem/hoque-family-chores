import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/badge.dart'; // This import will now properly refer to your Badge model
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/utils/enum_helpers.dart';

/// UserProfile extends FamilyMember with detailed gamification data and business logic.
class UserProfile extends FamilyMember {
  final int totalPoints;
  final int currentLevel;
  final int pointsToNextLevel;
  final int completedTasks;
  final int currentStreak;
  final int longestStreak;
  final List<Badge>
  unlockedBadges; // This type will now be correctly recognized
  final List<Reward> redeemedRewards;
  final List<String> achievements;
  final DateTime? lastTaskCompletedAt;
  final DateTime joinedAt;

  static const int _basePointsForLevel = 100;
  static const double _levelMultiplier = 1.5;

  UserProfile({
    required String id,
    required String name,
    String? email,
    String? avatarUrl,
    FamilyRole? role,
    String? familyId,
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
  }) : currentLevel = currentLevel ?? calculateLevelFromPoints(totalPoints),
       pointsToNextLevel =
           pointsToNextLevel ?? calculatePointsToNextLevel(totalPoints),
       super(
         id: id,
         name: name,
         email: email,
         avatarUrl: avatarUrl,
         role: role,
         familyId: familyId,
       );

  /// Create a copy of this profile with given fields replaced with new values
  @override
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    FamilyRole? role,
    String? familyId,
    int? totalPoints,
    int? currentLevel,
    int? pointsToNextLevel,
    int? completedTasks,
    int? currentStreak,
    int? longestStreak,
    List<Badge>? unlockedBadges, // Correctly typed
    List<Reward>? redeemedRewards,
    List<String>? achievements,
    DateTime? lastTaskCompletedAt,
    DateTime? joinedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
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

  /// Factory to create a UserProfile from a map (e.g., from Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    try {
      DateTime? parseDate(dynamic dateData) {
        if (dateData == null) return null;
        if (dateData is Timestamp) return dateData.toDate();
        if (dateData is String) return DateTime.tryParse(dateData);
        return null;
      }

      final role = enumFromString(
        map['role'] as String?,
        FamilyRole.values,
        defaultValue: FamilyRole.child,
      );
      return UserProfile(
        id: map['id'] ?? map['uid'] ?? '',
        name: map['name'] as String? ?? 'No Name',
        email: map['email'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        role: role,
        familyId: map['familyId'] as String?,
        totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
        completedTasks: (map['completedTasks'] as num?)?.toInt() ?? 0,
        currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
        unlockedBadges:
            (map['unlockedBadges'] as List<dynamic>?)
                ?.map((data) => Badge.fromMap(data))
                .toList() ??
            [],
        redeemedRewards:
            (map['redeemedRewards'] as List<dynamic>?)
                ?.map((data) => Reward.fromMap(data))
                .toList() ??
            [],
        achievements: List<String>.from(map['achievements'] ?? []),
        lastTaskCompletedAt: parseDate(map['lastTaskCompletedAt']),
        joinedAt: parseDate(map['joinedAt']) ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing UserProfile.fromMap: $e');
      return UserProfile(id: '', name: 'Unknown', joinedAt: DateTime.now());
    }
  }

  /// Create a UserProfile from a Firestore document.
  factory UserProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    return UserProfile.fromMap({...doc.data()!, 'id': doc.id});
  }

  /// Convert UserProfile to JSON for Firestore
  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'pointsToNextLevel': pointsToNextLevel,
      'completedTasks': completedTasks,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'unlockedBadges':
          unlockedBadges
              .map((badge) => badge.toJson())
              .toList(), // toJson can be unconditionally invoked
      'redeemedRewards':
          redeemedRewards.map((reward) => reward.toJson()).toList(),
      'achievements': achievements,
      'lastTaskCompletedAt':
          lastTaskCompletedAt != null
              ? Timestamp.fromDate(lastTaskCompletedAt!)
              : null,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  // --- All of your existing business logic methods ---

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

  /// Calculate points needed to reach the next level
  static int calculatePointsToNextLevel(int currentPoints) {
    int currentLevel = calculateLevelFromPoints(currentPoints);
    int nextLevelPoints =
        (_basePointsForLevel * (1 + currentLevel * _levelMultiplier)).toInt();
    int pointsNeeded = nextLevelPoints - currentPoints;
    return pointsNeeded > 0 ? pointsNeeded : 0;
  }

  /// Calculate progress percentage to the next level (0-100)
  int get levelProgressPercentage {
    if (currentLevel == 0) {
      if (_basePointsForLevel == 0) return 0;
      return ((totalPoints / _basePointsForLevel) * 100).clamp(0, 100).toInt();
    }

    int previousLevelPoints =
        (_basePointsForLevel * (1 + (currentLevel - 1) * _levelMultiplier))
            .toInt();
    int nextLevelPoints =
        (_basePointsForLevel * (1 + currentLevel * _levelMultiplier)).toInt();
    int pointsInCurrentLevel = totalPoints - previousLevelPoints;
    int pointsRequiredForCurrentLevel = nextLevelPoints - previousLevelPoints;

    if (pointsRequiredForCurrentLevel <= 0) return 100;

    return ((pointsInCurrentLevel / pointsRequiredForCurrentLevel) * 100)
        .clamp(0, 100)
        .toInt();
  }

  /// Check if user has a specific badge by its ID
  bool hasBadge(String badgeId) {
    return unlockedBadges.any((badge) => badge.id == badgeId);
  }

  /// Check if user has redeemed a specific reward by its ID
  bool hasRedeemedReward(String rewardId) {
    return redeemedRewards.any((reward) => reward.id == rewardId);
  }

  /// Check if user has a specific achievement by its ID
  bool hasAchievement(String achievementId) {
    return achievements.contains(achievementId);
  }

  /// Returns a new UserProfile with an updated streak based on the last completion date.
  UserProfile updateStreak() {
    if (lastTaskCompletedAt == null) {
      return copyWith(
        currentStreak: 1,
        longestStreak: 1,
        lastTaskCompletedAt: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastCompletionDate = DateTime(
      lastTaskCompletedAt!.year,
      lastTaskCompletedAt!.month,
      lastTaskCompletedAt!.day,
    );

    if (lastCompletionDate.isAtSameMomentAs(today)) {
      return this;
    } else if (lastCompletionDate.isAtSameMomentAs(yesterday)) {
      final newStreak = currentStreak + 1;
      return copyWith(
        currentStreak: newStreak,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
        lastTaskCompletedAt: now,
      );
    } else {
      return copyWith(currentStreak: 1, lastTaskCompletedAt: now);
    }
  }

  /// Returns a new UserProfile with added points.
  UserProfile addPoints(int points) {
    return copyWith(totalPoints: totalPoints + points);
  }

  /// Returns a new UserProfile after completing a task.
  UserProfile completeTask(int taskPoints) {
    final withPoints = addPoints(taskPoints);
    final withStreak = withPoints.updateStreak();

    return withStreak.copyWith(completedTasks: completedTasks + 1);
  }

  /// Returns a new UserProfile with a newly unlocked badge.
  UserProfile unlockBadge(Badge badge) {
    // Correctly typed
    if (hasBadge(badge.id)) return this;

    final unlockedBadge = badge.copyWith(
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );

    return copyWith(unlockedBadges: [...unlockedBadges, unlockedBadge]);
  }

  /// Returns a new UserProfile after redeeming a reward, if points are sufficient.
  UserProfile redeemReward(Reward reward) {
    if (totalPoints < reward.pointsCost) {
      throw Exception('Not enough points to redeem this reward.');
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

  /// Checks the user's current stats against a list of available badges and returns any new ones they have earned.
  List<Badge> checkForNewBadges(List<Badge> availableBadges) {
    // Correctly typed
    final newBadges = <Badge>[]; // Correctly typed

    for (final badge in availableBadges) {
      if (hasBadge(badge.id)) continue;

      bool shouldUnlock = false;
      switch (badge.category) {
        case BadgeCategory.taskMaster:
          shouldUnlock = completedTasks >= _getTaskThresholdForBadge(badge.id);
          break;
        case BadgeCategory.streaker:
          shouldUnlock = currentStreak >= _getStreakThresholdForBadge(badge.id);
          break;
        case BadgeCategory.varietyKing:
        case BadgeCategory.superHelper:
          shouldUnlock = true;
          break;
      }
      if (shouldUnlock) {
        newBadges.add(badge);
      }
    }

    return newBadges;
  }

  /// Helper method to get task threshold for task master badges
  int _getTaskThresholdForBadge(String badgeId) {
    switch (badgeId) {
      case 'badge_task_master_1':
        return 5;
      case 'badge_task_master_2':
        return 15;
      case 'badge_task_master_3':
        return 30;
      case 'badge_task_master_4':
        return 50;
      case 'badge_task_master_5':
        return 100;
    }
    return 999999;
  }

  /// Helper method to get streak threshold for streaker badges
  int _getStreakThresholdForBadge(String badgeId) {
    switch (badgeId) {
      case 'badge_consistent_1':
        return 2;
      case 'badge_consistent_2':
        return 7;
      case 'badge_consistent_3':
        return 30;
    }
    return 999999;
  }

  /// A readable string representation of the UserProfile object.
  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, role: $role, points: $totalPoints, level: $currentLevel)';
  }
}
