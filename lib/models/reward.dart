// lib/models/reward.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/enum_helpers.dart'; // <--- NEW: Import enum_helpers

class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final String iconName;
  final RewardCategory category;
  final RewardRarity rarity;
  final bool isAvailable;
  final bool isRedeemed;
  final DateTime? redeemedAt;
  final String? redeemedBy;

  const Reward({
    required this.id,
    required this.title,
    this.description = '',
    required this.pointsCost,
    this.iconName = 'card_giftcard',
    required this.category,
    required this.rarity,
    this.isAvailable = true,
    this.isRedeemed = false,
    this.redeemedAt,
    this.redeemedBy,
  });

  factory Reward.fromMap(Map<String, dynamic> map) {
    // Use enumFromString for RewardCategory
    final category = enumFromString(
      map['category'] as String?,
      RewardCategory.values,
      defaultValue: RewardCategory.physical,
    );

    // Use enumFromString for RewardRarity
    final rarity = enumFromString(
      map['rarity'] as String?,
      RewardRarity.values,
      defaultValue: RewardRarity.common,
    );

    return Reward(
      id: map['id'] ?? '',
      title: map['title'] as String? ?? 'No Title',
      description: map['description'] as String? ?? '',
      pointsCost: (map['pointsCost'] as num?)?.toInt() ?? 0,
      iconName: map['iconName'] as String? ?? 'card_giftcard',
      category: category, // Use parsed category
      rarity: rarity, // Use parsed rarity
      isAvailable: map['isAvailable'] as bool? ?? true,
      isRedeemed: map['isRedeemed'] as bool? ?? false,
      redeemedAt: (map['redeemedAt'] as Timestamp?)?.toDate(),
      redeemedBy: map['redeemedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'iconName': iconName,
      'category': category.name,
      'rarity': rarity.name,
      'isAvailable': isAvailable,
      'isRedeemed': isRedeemed,
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'redeemedBy': redeemedBy,
    };
  }

  Reward copyWith({
    String? id, String? title, String? description, int? pointsCost,
    String? iconName, RewardCategory? category, RewardRarity? rarity,
    bool? isAvailable, bool? isRedeemed, DateTime? redeemedAt, String? redeemedBy,
  }) {
    return Reward(
      id: id ?? this.id, title: title ?? this.title, description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost, iconName: iconName ?? this.iconName,
      category: category ?? this.category, rarity: rarity ?? this.rarity,
      isAvailable: isAvailable ?? this.isAvailable, isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt, redeemedBy: redeemedBy ?? this.redeemedBy,
    );
  }
}