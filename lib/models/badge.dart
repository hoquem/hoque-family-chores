// lib/models/badge.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Categories of badges that can be earned
enum BadgeCategory {
  taskMaster, // For completing many tasks
  streaker,   // For maintaining streaks
  helper,     // For helping others
  cleaner,    // For cleaning tasks
  organizer,  // For organizing tasks
  cook,       // For cooking tasks
  outdoor,    // For outdoor tasks
  special     // For special achievements
}

/// Rarity levels for badges
enum BadgeRarity {
  common,    // Easy to obtain
  uncommon,  // Moderately difficult
  rare,      // Difficult to obtain
  epic,      // Very difficult to obtain
  legendary  // Extremely difficult to obtain
}

/// Extension to get color based on badge rarity
extension BadgeRarityColor on BadgeRarity {
  Color get color {
    switch (this) {
      case BadgeRarity.common:
        return Colors.grey.shade400;
      case BadgeRarity.uncommon:
        return Colors.green.shade400;
      case BadgeRarity.rare:
        return Colors.blue.shade400;
      case BadgeRarity.epic:
        return Colors.purple.shade400;
      case BadgeRarity.legendary:
        return Colors.orange.shade400;
    }
  }
  
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.uncommon:
        return 'Uncommon';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
    }
  }
}

/// Extension to get display name for badge category
extension BadgeCategoryName on BadgeCategory {
  String get displayName {
    switch (this) {
      case BadgeCategory.taskMaster:
        return 'Task Master';
      case BadgeCategory.streaker:
        return 'Streaker';
      case BadgeCategory.helper:
        return 'Helper';
      case BadgeCategory.cleaner:
        return 'Cleaner';
      case BadgeCategory.organizer:
        return 'Organizer';
      case BadgeCategory.cook:
        return 'Cook';
      case BadgeCategory.outdoor:
        return 'Outdoor';
      case BadgeCategory.special:
        return 'Special';
    }
  }
}

/// Badge model representing achievements in the app
class Badge {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String color; // Hex color code
  final int requiredPoints;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.color,
    required this.requiredPoints,
    required this.category,
    required this.rarity,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Create a copy of this badge with given fields replaced with new values
  Badge copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    String? color,
    int? requiredPoints,
    BadgeCategory? category,
    BadgeRarity? rarity,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Badge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Create a Badge from a Firestore document
  factory Badge.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Badge(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      iconName: data['iconName'] as String,
      color: data['color'] as String,
      requiredPoints: data['requiredPoints'] as int,
      category: BadgeCategory.values[data['category'] as int],
      rarity: BadgeRarity.values[data['rarity'] as int],
      isUnlocked: data['isUnlocked'] as bool? ?? false,
      unlockedAt: data['unlockedAt'] != null 
          ? (data['unlockedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  /// Convert Badge to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'iconName': iconName,
      'color': color,
      'requiredPoints': requiredPoints,
      'category': category.index,
      'rarity': rarity.index,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  /// Get all predefined badges
  static List<Badge> getPredefinedBadges() {
    return [
      // Task Master Badges
      Badge(
        id: 'task_master_1',
        title: 'Task Beginner',
        description: 'Complete 5 tasks',
        iconName: 'task_beginner',
        color: '#4CAF50', // Green
        requiredPoints: 50,
        category: BadgeCategory.taskMaster,
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'task_master_2',
        title: 'Task Apprentice',
        description: 'Complete 15 tasks',
        iconName: 'task_apprentice',
        color: '#2196F3', // Blue
        requiredPoints: 150,
        category: BadgeCategory.taskMaster,
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'task_master_3',
        title: 'Task Expert',
        description: 'Complete 30 tasks',
        iconName: 'task_expert',
        color: '#9C27B0', // Purple
        requiredPoints: 300,
        category: BadgeCategory.taskMaster,
        rarity: BadgeRarity.rare,
      ),
      Badge(
        id: 'task_master_4',
        title: 'Task Master',
        description: 'Complete 50 tasks',
        iconName: 'task_master',
        color: '#FF9800', // Orange
        requiredPoints: 500,
        category: BadgeCategory.taskMaster,
        rarity: BadgeRarity.epic,
      ),
      Badge(
        id: 'task_master_5',
        title: 'Task Legend',
        description: 'Complete 100 tasks',
        iconName: 'task_legend',
        color: '#F44336', // Red
        requiredPoints: 1000,
        category: BadgeCategory.taskMaster,
        rarity: BadgeRarity.legendary,
      ),

      // Streaker Badges
      Badge(
        id: 'streaker_1',
        title: 'Weekend Warrior',
        description: 'Complete tasks on 2 consecutive days',
        iconName: 'weekend_warrior',
        color: '#4CAF50', // Green
        requiredPoints: 20,
        category: BadgeCategory.streaker,
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'streaker_2',
        title: 'Week Warrior',
        description: 'Complete tasks on 7 consecutive days',
        iconName: 'week_warrior',
        color: '#2196F3', // Blue
        requiredPoints: 70,
        category: BadgeCategory.streaker,
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'streaker_3',
        title: 'Month Warrior',
        description: 'Complete tasks on 30 consecutive days',
        iconName: 'month_warrior',
        color: '#9C27B0', // Purple
        requiredPoints: 300,
        category: BadgeCategory.streaker,
        rarity: BadgeRarity.epic,
      ),

      // Helper Badges
      Badge(
        id: 'helper_1',
        title: 'Helping Hand',
        description: 'Help another family member with their task',
        iconName: 'helping_hand',
        color: '#4CAF50', // Green
        requiredPoints: 30,
        category: BadgeCategory.helper,
        rarity: BadgeRarity.common,
      ),
      Badge(
        id: 'helper_2',
        title: 'Super Helper',
        description: 'Help family members 5 times',
        iconName: 'super_helper',
        color: '#2196F3', // Blue
        requiredPoints: 150,
        category: BadgeCategory.helper,
        rarity: BadgeRarity.uncommon,
      ),

      // Cleaner Badges
      Badge(
        id: 'cleaner_1',
        title: 'Neat Freak',
        description: 'Complete 10 cleaning tasks',
        iconName: 'neat_freak',
        color: '#4CAF50', // Green
        requiredPoints: 100,
        category: BadgeCategory.cleaner,
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'cleaner_2',
        title: 'Cleaning Champion',
        description: 'Complete 25 cleaning tasks',
        iconName: 'cleaning_champion',
        color: '#9C27B0', // Purple
        requiredPoints: 250,
        category: BadgeCategory.cleaner,
        rarity: BadgeRarity.rare,
      ),

      // Special Badges
      Badge(
        id: 'special_1',
        title: 'Early Bird',
        description: 'Complete a task before 8 AM',
        iconName: 'early_bird',
        color: '#4CAF50', // Green
        requiredPoints: 50,
        category: BadgeCategory.special,
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'special_2',
        title: 'Night Owl',
        description: 'Complete a task after 8 PM',
        iconName: 'night_owl',
        color: '#2196F3', // Blue
        requiredPoints: 50,
        category: BadgeCategory.special,
        rarity: BadgeRarity.uncommon,
      ),
      Badge(
        id: 'special_3',
        title: 'Overachiever',
        description: 'Complete 3 tasks in a single day',
        iconName: 'overachiever',
        color: '#9C27B0', // Purple
        requiredPoints: 100,
        category: BadgeCategory.special,
        rarity: BadgeRarity.rare,
      ),
      Badge(
        id: 'special_4',
        title: 'Family Hero',
        description: 'Earn the most points in a month',
        iconName: 'family_hero',
        color: '#F44336', // Red
        requiredPoints: 500,
        category: BadgeCategory.special,
        rarity: BadgeRarity.legendary,
      ),
    ];
  }
}
