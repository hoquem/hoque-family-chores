// lib/models/reward.dart
import 'package:hoque_family_chores/models/enums.dart';

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

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.iconName,
    required this.category,
    required this.rarity,
    this.isAvailable = true,
    this.isRedeemed = false,
    this.redeemedAt,
    this.redeemedBy,
  });

  Reward copyWith({bool? isRedeemed, DateTime? redeemedAt, String? redeemedBy}) {
    return Reward(
      id: id,
      title: title,
      description: description,
      pointsCost: pointsCost,
      iconName: iconName,
      category: category,
      rarity: rarity,
      isAvailable: isAvailable,
      isRedeemed: isRedeemed ?? this.isRedeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
    );
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    return Reward(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Reward',
      description: map['description'] ?? '',
      pointsCost: (map['pointsCost'] as num?)?.toInt() ?? 0,
      iconName: map['iconName'] ?? 'card_giftcard',
      category: RewardCategory.values.byName(map['category'] ?? 'digital'),
      rarity: RewardRarity.values.byName(map['rarity'] ?? 'common'),
      isAvailable: map['isAvailable'] ?? true,
      isRedeemed: map['isRedeemed'] ?? false,
      redeemedAt: map['redeemedAt'] != null ? DateTime.tryParse(map['redeemedAt']) : null,
      redeemedBy: map['redeemedBy'],
    );
  }
  
  Map<String, dynamic> toJson() => {
      'id': id,
      'title': title,
      'description': description,
      'pointsCost': pointsCost,
      'iconName': iconName,
      'category': category.name,
      'rarity': rarity.name,
      'isAvailable': isAvailable,
      'isRedeemed': isRedeemed,
      'redeemedAt': redeemedAt?.toIso8601String(),
      'redeemedBy': redeemedBy,
    };
}