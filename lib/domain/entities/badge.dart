import 'package:equatable/equatable.dart';
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';

/// Domain entity representing a badge
class Badge extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final Points requiredPoints;
  final BadgeType type;
  final FamilyId familyId;
  final String? creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BadgeRarity rarity;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.requiredPoints,
    required this.type,
    required this.familyId,
    this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.rarity = BadgeRarity.common,
  });

  /// Creates a copy of this badge with updated fields
  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    Points? requiredPoints,
    BadgeType? type,
    FamilyId? familyId,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    BadgeRarity? rarity,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      type: type ?? this.type,
      familyId: familyId ?? this.familyId,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rarity: rarity ?? this.rarity,
    );
  }

  /// Check if a user can earn this badge based on their points
  bool canBeEarned(Points userPoints) {
    return userPoints.isGreaterThan(requiredPoints) || userPoints.isEqualTo(requiredPoints);
  }

  /// Get the category of this badge
  BadgeCategory get category {
    switch (type) {
      case BadgeType.taskCompletion:
        return BadgeCategory.taskMaster;
      case BadgeType.streak:
        return BadgeCategory.streaker;
      case BadgeType.points:
        return BadgeCategory.superHelper;
      default:
        return BadgeCategory.taskMaster;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconName,
        requiredPoints,
        type,
        familyId,
        creatorId,
        createdAt,
        updatedAt,
        rarity,
      ];
}

/// Badge types
enum BadgeType {
  taskCompletion, // Complete X tasks
  streak, // Maintain a streak for X days
  points, // Reach X points
  special, // Special achievements
  custom, // Custom badges created by admin
  achievement,
  milestone,
}

/// Badge categories
enum BadgeCategory {
  taskMaster,
  streaker,
  varietyKing,
  superHelper;

  String get displayName {
    switch (this) {
      case BadgeCategory.taskMaster:
        return 'Task Master';
      case BadgeCategory.streaker:
        return 'Streaker';
      case BadgeCategory.varietyKing:
        return 'Variety King';
      case BadgeCategory.superHelper:
        return 'Super Helper';
    }
  }
}

/// Badge rarity levels
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

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