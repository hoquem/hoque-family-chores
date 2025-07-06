import 'package:equatable/equatable.dart';
import '../value_objects/family_id.dart';
import '../value_objects/points.dart';

/// Domain entity representing a reward
class Reward extends Equatable {
  final String id;
  final String name;
  final String description;
  final Points pointsCost;
  final String iconName;
  final RewardType type;
  final FamilyId familyId;
  final String? creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RewardRarity rarity;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.iconName,
    required this.type,
    required this.familyId,
    this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    this.rarity = RewardRarity.common,
  });

  /// Creates a copy of this reward with updated fields
  Reward copyWith({
    String? id,
    String? name,
    String? description,
    Points? pointsCost,
    String? iconName,
    RewardType? type,
    FamilyId? familyId,
    String? creatorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    RewardRarity? rarity,
  }) {
    return Reward(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      familyId: familyId ?? this.familyId,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rarity: rarity ?? this.rarity,
    );
  }

  /// Check if a user can afford this reward
  bool canBeAfforded(Points userPoints) {
    return userPoints.isGreaterThan(pointsCost) || userPoints.isEqualTo(pointsCost);
  }

  /// Get the cost in points as an integer
  int get costAsInt => pointsCost.toInt();

  /// Check if reward is available (always true for now, can be extended)
  bool get isAvailable => true;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        pointsCost,
        iconName,
        type,
        familyId,
        creatorId,
        createdAt,
        updatedAt,
        rarity,
      ];
}

/// Reward types
enum RewardType {
  digital,
  physical,
  privilege;

  String get displayName {
    switch (this) {
      case RewardType.digital:
        return 'Digital';
      case RewardType.physical:
        return 'Physical';
      case RewardType.privilege:
        return 'Privilege';
    }
  }
}

/// Reward categories
enum RewardCategory {
  digital(displayName: 'Digital'),
  physical(displayName: 'Physical'),
  privilege(displayName: 'Privilege');

  const RewardCategory({required this.displayName});
  final String displayName;
}

/// Reward rarity levels
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
} 