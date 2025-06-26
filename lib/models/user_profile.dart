import 'package:hoque_family_chores/models/family_member.dart';

/// UserProfile extends FamilyMember with detailed gamification data and business logic.
class UserProfile {
  final String id;
  final FamilyMember member;
  final int points;
  final List<String> badges;
  final List<String> achievements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;
  final String? bio;
  final List<String> completedTasks;
  final List<String> inProgressTasks;
  final List<String> availableTasks;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> statistics;

  UserProfile({
    required this.id,
    required this.member,
    required this.points,
    required this.badges,
    required this.achievements,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.bio,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.availableTasks,
    required this.preferences,
    required this.statistics,
  });

  UserProfile copyWith({
    String? id,
    FamilyMember? member,
    int? points,
    List<String>? badges,
    List<String>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? avatarUrl,
    String? bio,
    List<String>? completedTasks,
    List<String>? inProgressTasks,
    List<String>? availableTasks,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) {
    return UserProfile(
      id: id ?? this.id,
      member: member ?? this.member,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      completedTasks: completedTasks ?? this.completedTasks,
      inProgressTasks: inProgressTasks ?? this.inProgressTasks,
      availableTasks: availableTasks ?? this.availableTasks,
      preferences: preferences ?? this.preferences,
      statistics: statistics ?? this.statistics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'points': points,
      'badges': badges,
      'achievements': achievements,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'avatarUrl': avatarUrl,
      'bio': bio,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'availableTasks': availableTasks,
      'preferences': preferences,
      'statistics': statistics,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to list
    List<String> _safeListFromJson(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return List<String>.from(value);
      }
      // If it's not a list, return empty list
      return [];
    }

    return UserProfile(
      id: json['id'] as String,
      member: json['member'] != null 
          ? FamilyMember.fromJson(json['member'] as Map<String, dynamic>)
          : FamilyMember(
              id: json['id'] as String,
              userId: json['id'] as String, // Use id as userId for fallback
              familyId: json['familyId'] as String? ?? 'unknown',
              name: json['name'] as String? ?? 'Unknown User',
              photoUrl: json['avatarUrl'] as String?,
              role: FamilyRole.child, // Default to child role
              points: json['points'] as int? ?? 0,
              joinedAt: json['createdAt'] != null 
                  ? DateTime.parse(json['createdAt'] as String)
                  : DateTime.now(),
              updatedAt: json['updatedAt'] != null 
                  ? DateTime.parse(json['updatedAt'] as String)
                  : DateTime.now(),
            ),
      points: json['points'] as int? ?? 0,
      badges: _safeListFromJson(json['badges']),
      achievements: _safeListFromJson(json['achievements']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      completedTasks: _safeListFromJson(json['completedTasks']),
      inProgressTasks: _safeListFromJson(json['inProgressTasks']),
      availableTasks: _safeListFromJson(json['availableTasks']),
      preferences: json['preferences'] != null 
          ? Map<String, dynamic>.from(json['preferences'] as Map)
          : <String, dynamic>{},
      statistics: json['statistics'] != null 
          ? Map<String, dynamic>.from(json['statistics'] as Map)
          : <String, dynamic>{},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.id == id &&
        other.member == member &&
        other.points == points &&
        other.badges == badges &&
        other.achievements == achievements &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio &&
        other.completedTasks == completedTasks &&
        other.inProgressTasks == inProgressTasks &&
        other.availableTasks == availableTasks &&
        other.preferences == preferences &&
        other.statistics == statistics;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      member,
      points,
      badges,
      achievements,
      createdAt,
      updatedAt,
      avatarUrl,
      bio,
      completedTasks,
      inProgressTasks,
      availableTasks,
      preferences,
      statistics,
    );
  }

  static const int _basePointsForLevel = 100;
  static const double _levelMultiplier = 1.5;

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

  /// Calculate points needed for next level
  static int calculatePointsForNextLevel(int currentLevel) {
    return (_basePointsForLevel * (1 + currentLevel * _levelMultiplier))
        .round();
  }

  /// Calculate progress to next level (0.0 to 1.0)
  double get progressToNextLevel {
    if (calculateLevelFromPoints(points) == 0) return 0.0;
    final pointsForCurrentLevel = calculatePointsForNextLevel(
      calculateLevelFromPoints(points) - 1,
    );
    final pointsForNextLevel = calculatePointsForNextLevel(
      calculateLevelFromPoints(points),
    );
    final pointsInCurrentLevel = points - pointsForCurrentLevel;
    final pointsNeededForNextLevel = pointsForNextLevel - pointsForCurrentLevel;
    return pointsInCurrentLevel / pointsNeededForNextLevel;
  }

  /// Check if user has earned a new level
  bool get hasLeveledUp {
    final calculatedLevel = calculateLevelFromPoints(points);
    return calculatedLevel > calculateLevelFromPoints(points);
  }

  /// Get the next level's required points
  int get nextLevelPoints {
    return calculatePointsForNextLevel(calculateLevelFromPoints(points));
  }

  /// Get the current level's starting points
  int get currentLevelPoints {
    return calculatePointsForNextLevel(calculateLevelFromPoints(points) - 1);
  }

  /// Get points earned in current level
  int get pointsInCurrentLevel {
    return points - currentLevelPoints;
  }

  /// Get points needed for next level
  int get pointsNeededForNextLevel {
    return nextLevelPoints - points;
  }

  /// Check if user has a specific badge
  bool hasBadge(String badgeId) {
    return badges.contains(badgeId);
  }

  /// Check if user has a specific achievement
  bool hasAchievement(String achievementId) {
    return achievements.contains(achievementId);
  }

  /// Get the user's current streak status
  bool get isOnStreak {
    if (updatedAt.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return false;
    }
    return true;
  }

  /// Get the user's streak status message
  String get streakStatus {
    if (calculateLevelFromPoints(points) == 0) return 'No streak yet';
    if (isOnStreak) {
      return 'On a ${calculateLevelFromPoints(points)} day streak!';
    }
    return 'Streak broken at ${calculateLevelFromPoints(points)} days';
  }

  /// Get the user's level progress message
  String get levelProgress {
    return 'Level ${calculateLevelFromPoints(points)} - ${(progressToNextLevel * 100).round()}% to next level';
  }

  /// Get the user's points status message
  String get pointsStatus {
    return '$points points ($pointsNeededForNextLevel to next level)';
  }

  /// Get the user's task completion status message
  String get taskCompletionStatus {
    return '${completedTasks.length} tasks completed';
  }

  /// Get the user's badge status message
  String get badgeStatus {
    return '${badges.length} badges earned';
  }

  /// Get the user's achievement status message
  String get achievementStatus {
    return '${achievements.length} achievements unlocked';
  }

  /// Get the user's overall status message
  String get overallStatus {
    return '$levelProgress\n$pointsStatus\n$taskCompletionStatus\n$streakStatus\n$badgeStatus\n$achievementStatus';
  }

  int get levelProgressPercentage {
    if (nextLevelPoints <= 0) return 100;
    return ((points % _basePointsForLevel) / _basePointsForLevel * 100).round();
  }
}

// --- User-related Enums (kept in this file for encapsulation) ---
enum UserRole { member, admin, moderator }
