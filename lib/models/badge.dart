import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/enums.dart';

// --- Badge-related Enums (kept in this file for encapsulation) ---
enum BadgeCategory {
  taskMaster(displayName: 'Task Master'),
  streaker(displayName: 'Streaker'),
  varietyKing(displayName: 'Variety King'),
  superHelper(displayName: 'Super Helper');

  const BadgeCategory({required this.displayName});
  final String displayName;
}

enum BadgeType {
  taskCompletion, // Complete X tasks
  streak, // Maintain a streak for X days
  points, // Reach X points
  special, // Special achievements
  custom, // Custom badges created by admin
  achievement,
  milestone,
}

enum BadgeRarity {
  common,
  rare,
  epic,
  legendary;

  Color get color {
    switch (this) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.orange;
    }
  }
}

class Badge {
  @override
  final String id;
  final String name;
  final String description;
  final String iconName; // Material icon name
  final int requiredPoints;
  final BadgeType type;
  final String familyId;
  final String? creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final BadgeRarity rarity;

  Badge._({
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

  factory Badge({
    required String id,
    required String name,
    required String description,
    required String iconName,
    required int requiredPoints,
    required BadgeType type,
    required String familyId,
    String? creatorId,
    required DateTime createdAt,
    required DateTime updatedAt,
    BadgeRarity rarity = BadgeRarity.common,
  }) {
    return Badge._(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      requiredPoints: requiredPoints,
      type: type,
      familyId: familyId,
      creatorId: creatorId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      rarity: rarity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'requiredPoints': requiredPoints,
      'type': type.name,
      'familyId': familyId,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rarity': rarity.name,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['iconName'] ?? 'emoji_events',
      requiredPoints: json['requiredPoints'] ?? 0,
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BadgeType.taskCompletion,
      ),
      familyId: json['familyId'] ?? '',
      creatorId: json['creatorId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => BadgeRarity.common,
      ),
    );
  }

  Badge copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? requiredPoints,
    BadgeType? type,
    String? familyId,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Badge &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.iconName == iconName &&
        other.requiredPoints == requiredPoints &&
        other.type == type &&
        other.familyId == familyId &&
        other.creatorId == creatorId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.rarity == rarity;
  }

  @override
  int get hashCode {
    return Object.hash(
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
    );
  }
}
