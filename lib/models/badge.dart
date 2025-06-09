// lib/models/badge.dart
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/enum_helpers.dart'; // Import the helper


class Badge {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final String color;
  final BadgeRarity rarity;
  final int requiredPoints;
  final BadgeCategory category;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.color,
    required this.rarity,
    this.requiredPoints = 0,
    required this.category,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    return Badge(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Unknown Badge',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'star',
      color: map['color'] as String? ?? '#808080',
      rarity: enumFromString(map['rarity'], BadgeRarity.values, defaultValue: BadgeRarity.common),
      requiredPoints: (map['requiredPoints'] as num?)?.toInt() ?? 0,
      category: enumFromString(map['category'], BadgeCategory.values, defaultValue: BadgeCategory.taskMaster),
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: map['unlockedAt'] != null ? DateTime.tryParse(map['unlockedAt'].toString()) : null,
    );
  }

  Badge copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Badge(
      id: id,
      title: title,
      description: description,
      iconName: iconName,
      color: color,
      rarity: rarity,
      requiredPoints: requiredPoints,
      category: category,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconName': iconName,
      'color': color,
      'rarity': rarity.name,
      'requiredPoints': requiredPoints,
      'category': category.name,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}