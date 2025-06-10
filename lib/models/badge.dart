import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/enums.dart';
import 'package:hoque_family_chores/utils/enum_helpers.dart';

class Badge { // This is your custom Badge class
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final int requiredPoints;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    required this.category,
    required this.rarity,
    this.requiredPoints = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Badge.fromMap(Map<String, dynamic> map) {
    final category = enumFromString(
      map['category'] as String?,
      BadgeCategory.values,
      defaultValue: BadgeCategory.taskMaster,
    );

    final rarity = enumFromString(
      map['rarity'] as String?,
      BadgeRarity.values,
      defaultValue: BadgeRarity.common,
    );

    return Badge(
      id: map['id'] ?? '',
      name: map['name'] as String? ?? 'No Name',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? (map['iconName'] != null ? 'assets/icons/${map['iconName']}.png' : ''),
      category: category,
      rarity: rarity,
      requiredPoints: (map['requiredPoints'] as num?)?.toInt() ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category.name,
      'rarity': rarity.name,
      'requiredPoints': requiredPoints,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  Badge copyWith({
    String? id, String? name, String? description, String? imageUrl,
    BadgeCategory? category, BadgeRarity? rarity, int? requiredPoints,
    bool? isUnlocked, DateTime? unlockedAt,
  }) {
    return Badge(
      id: id ?? this.id, name: name ?? this.name, description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl, category: category ?? this.category,
      rarity: rarity ?? this.rarity, requiredPoints: requiredPoints ?? this.requiredPoints,
      isUnlocked: isUnlocked ?? this.isUnlocked, unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}