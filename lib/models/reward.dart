// lib/models/reward.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enum for reward categories
enum RewardCategory {
  activity,
  item,
  privilege,
  allowance,
  screenTime,
  custom;

  String get displayName {
    switch (this) {
      case RewardCategory.activity:
        return 'Activity';
      case RewardCategory.item:
        return 'Item';
      case RewardCategory.privilege:
        return 'Privilege';
      case RewardCategory.allowance:
        return 'Allowance';
      case RewardCategory.screenTime:
        return 'Screen Time';
      case RewardCategory.custom:
        return 'Custom';
    }
  }
}

/// Enum for reward rarity
enum RewardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  String get displayName {
    switch (this) {
      case RewardRarity.common:
        return 'Common';
      case RewardRarity.uncommon:
        return 'Uncommon';
      case RewardRarity.rare:
        return 'Rare';
      case RewardRarity.epic:
        return 'Epic';
      case RewardRarity.legendary:
        return 'Legendary';
    }
  }

  Color get color {
    switch (this) {
      case RewardRarity.common:
        return Colors.grey.shade700;
      case RewardRarity.uncommon:
        return Colors.green.shade700;
      case RewardRarity.rare:
        return Colors.blue.shade700;
      case RewardRarity.epic:
        return Colors.purple.shade700;
      case RewardRarity.legendary:
        return Colors.orange.shade700;
    }
  }
}

/// Class representing a reward that can be redeemed with points
class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final RewardCategory category;
  final RewardRarity rarity;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final String? redeemedBy;
  final bool isAvailable; // Whether the reward can be redeemed multiple times

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconName,
    required this.category,
    required this.rarity,
    this.isRedeemed = false,
    this.redeemedAt,
    this.redeemedBy,
    this.isAvailable = true,
  });

  /// Create a reward from a Firestore document snapshot
  factory Reward.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Reward(
      id: snapshot.id,
      title: data['title'] as String,
      description: data['description'] as String,
      pointsCost: data['pointsCost'] as int,
      iconName: data['iconName'] as String,
      category: RewardCategory.values[data['category'] as int],
      rarity: RewardRarity.values[data['rarity'] as int],
      isRedeemed: data['isRedeemed'] as bool? ?? false,
      redeemedAt: data['redeemedAt'] != null 
          ? (data['redeemedAt'] as Timestamp).toDate() 
          : null,
      redeemedBy: data['redeemedBy'] as String?,
      isAvailable: data['isAvailable'] as bool? ?? true,
    );
  }

  /// Convert reward to a JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'iconName': iconName,
      'category': category.index,
      'rarity': rarity.index,
      'isRedeemed': isRedeemed,
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'redeemedBy': redeemedBy,
      'isAvailable': isAvailable,
    };
  }

  /// Create a copy of this reward with some properties changed
  Reward copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsCost,
    String? iconName,
    RewardCategory? category,
    RewardRarity? rarity,
    bool? isRedeemed,
    DateTime? redeemedAt,
    String? redeemedBy,
    bool? isAvailable,
  }) {
    return Reward(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// Mark this reward as redeemed
  Reward redeem(String userId) {
    if (isRedeemed && !isAvailable) {
      throw Exception('This reward has already been redeemed and is not available again');
    }
    
    return copyWith(
      isRedeemed: true,
      redeemedAt: DateTime.now(),
      redeemedBy: userId,
    );
  }

  /// Get a list of predefined rewards
  static List<Reward> getPredefinedRewards() {
    return [
      // Activity rewards
      const Reward(
        id: 'movie_night',
        title: 'Movie Night',
        description: 'Choose a movie for the whole family to watch',
        pointsCost: 100,
        iconName: 'movie',
        category: RewardCategory.activity,
        rarity: RewardRarity.common,
      ),
      const Reward(
        id: 'game_night',
        title: 'Game Night',
        description: 'Choose a board game for the whole family to play',
        pointsCost: 150,
        iconName: 'game',
        category: RewardCategory.activity,
        rarity: RewardRarity.common,
      ),
      const Reward(
        id: 'park_trip',
        title: 'Park Trip',
        description: 'Special trip to the park of your choice',
        pointsCost: 200,
        iconName: 'park',
        category: RewardCategory.activity,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'ice_cream_trip',
        title: 'Ice Cream Trip',
        description: 'Special trip to get ice cream',
        pointsCost: 250,
        iconName: 'ice_cream',
        category: RewardCategory.activity,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'restaurant_choice',
        title: 'Restaurant Choice',
        description: 'Choose where the family eats out next time',
        pointsCost: 350,
        iconName: 'restaurant',
        category: RewardCategory.activity,
        rarity: RewardRarity.rare,
      ),
      const Reward(
        id: 'special_outing',
        title: 'Special Outing',
        description: 'Special trip to a place of your choice (zoo, museum, etc.)',
        pointsCost: 500,
        iconName: 'outing',
        category: RewardCategory.activity,
        rarity: RewardRarity.epic,
      ),
      const Reward(
        id: 'theme_park',
        title: 'Theme Park Trip',
        description: 'Special trip to a theme park',
        pointsCost: 1000,
        iconName: 'theme_park',
        category: RewardCategory.activity,
        rarity: RewardRarity.legendary,
        isAvailable: false,
      ),
      
      // Item rewards
      const Reward(
        id: 'small_toy',
        title: 'Small Toy',
        description: 'A small toy of your choice (under \$10)',
        pointsCost: 200,
        iconName: 'toy',
        category: RewardCategory.item,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'medium_toy',
        title: 'Medium Toy',
        description: 'A medium-sized toy of your choice (under \$25)',
        pointsCost: 400,
        iconName: 'toy',
        category: RewardCategory.item,
        rarity: RewardRarity.rare,
      ),
      const Reward(
        id: 'large_toy',
        title: 'Large Toy',
        description: 'A large toy or game of your choice (under \$50)',
        pointsCost: 800,
        iconName: 'toy',
        category: RewardCategory.item,
        rarity: RewardRarity.epic,
        isAvailable: false,
      ),
      
      // Allowance rewards
      const Reward(
        id: 'allowance_bonus_5',
        title: '\$5 Allowance Bonus',
        description: 'Extra \$5 added to your allowance',
        pointsCost: 150,
        iconName: 'money',
        category: RewardCategory.allowance,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'allowance_bonus_10',
        title: '\$10 Allowance Bonus',
        description: 'Extra \$10 added to your allowance',
        pointsCost: 300,
        iconName: 'money',
        category: RewardCategory.allowance,
        rarity: RewardRarity.rare,
      ),
      const Reward(
        id: 'allowance_bonus_20',
        title: '\$20 Allowance Bonus',
        description: 'Extra \$20 added to your allowance',
        pointsCost: 600,
        iconName: 'money',
        category: RewardCategory.allowance,
        rarity: RewardRarity.epic,
      ),
      
      // Screen time rewards
      const Reward(
        id: 'extra_30min_screen',
        title: '30 Min Extra Screen Time',
        description: '30 minutes of extra screen time',
        pointsCost: 50,
        iconName: 'screen_time',
        category: RewardCategory.screenTime,
        rarity: RewardRarity.common,
      ),
      const Reward(
        id: 'extra_1hour_screen',
        title: '1 Hour Extra Screen Time',
        description: '1 hour of extra screen time',
        pointsCost: 100,
        iconName: 'screen_time',
        category: RewardCategory.screenTime,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'extra_2hour_screen',
        title: '2 Hours Extra Screen Time',
        description: '2 hours of extra screen time',
        pointsCost: 200,
        iconName: 'screen_time',
        category: RewardCategory.screenTime,
        rarity: RewardRarity.rare,
      ),
      
      // Privilege rewards
      const Reward(
        id: 'stay_up_late',
        title: 'Stay Up Late',
        description: 'Stay up 30 minutes past bedtime',
        pointsCost: 75,
        iconName: 'bedtime',
        category: RewardCategory.privilege,
        rarity: RewardRarity.common,
      ),
      const Reward(
        id: 'skip_one_chore',
        title: 'Skip One Chore',
        description: 'Skip one assigned chore of your choice',
        pointsCost: 150,
        iconName: 'skip',
        category: RewardCategory.privilege,
        rarity: RewardRarity.uncommon,
      ),
      const Reward(
        id: 'choose_dinner',
        title: 'Choose Dinner',
        description: 'Choose what the family has for dinner',
        pointsCost: 100,
        iconName: 'dinner',
        category: RewardCategory.privilege,
        rarity: RewardRarity.common,
      ),
      const Reward(
        id: 'no_chores_day',
        title: 'No Chores Day',
        description: 'Skip all chores for one day',
        pointsCost: 300,
        iconName: 'skip_all',
        category: RewardCategory.privilege,
        rarity: RewardRarity.rare,
      ),
    ];
  }
}
