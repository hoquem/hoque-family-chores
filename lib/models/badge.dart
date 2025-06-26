import 'package:flutter/material.dart';
import 'package:hoque_family_chores/utils/json_parser.dart';
import 'package:hoque_family_chores/utils/logger.dart';

// --- Badge-related Enums (co-located for encapsulation) ---
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
  common(color: Colors.brown, displayName: 'Common'),
  uncommon(color: Colors.blueGrey, displayName: 'Uncommon'),
  rare(color: Colors.blue, displayName: 'Rare'),
  epic(color: Colors.purpleAccent, displayName: 'Epic'),
  legendary(color: Colors.amber, displayName: 'Legendary');

  const BadgeRarity({required this.color, required this.displayName});
  final Color color;
  final String displayName;
}

class Badge {
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

  // --- Convenience getters for backward compatibility ---
  String? get imageUrl => null; // Badge uses iconName instead of imageUrl
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
    final logger = AppLogger();
    
    try {
      return Badge(
        id: JsonParser.parseRequiredString(json, 'id'),
        name: JsonParser.parseRequiredString(json, 'name'),
        description: JsonParser.parseRequiredString(json, 'description'),
        iconName: JsonParser.parseString(json, 'iconName', defaultValue: 'emoji_events') ?? 'emoji_events',
        requiredPoints: JsonParser.parseInt(json, 'requiredPoints', defaultValue: 0) ?? 0,
        type: JsonParser.parseRequiredEnum(json, 'type', BadgeType.values, BadgeType.taskCompletion),
        familyId: JsonParser.parseString(json, 'familyId', defaultValue: '') ?? '',
        creatorId: JsonParser.parseString(json, 'creatorId'),
        createdAt: JsonParser.parseRequiredDateTime(json, 'createdAt'),
        updatedAt: JsonParser.parseRequiredDateTime(json, 'updatedAt'),
        rarity: JsonParser.parseRequiredEnum(json, 'rarity', BadgeRarity.values, BadgeRarity.common),
      );
    } catch (e) {
      logger.e('Failed to parse Badge from JSON: $e');
      logger.d('JSON data: $json');
      
      // Return a minimal valid badge with defaults
      return Badge(
        id: JsonParser.parseString(json, 'id') ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        name: JsonParser.parseString(json, 'name') ?? 'Unknown Badge',
        description: JsonParser.parseString(json, 'description') ?? 'Badge description not available',
        iconName: JsonParser.parseString(json, 'iconName', defaultValue: 'emoji_events') ?? 'emoji_events',
        requiredPoints: JsonParser.parseInt(json, 'requiredPoints', defaultValue: 0) ?? 0,
        type: JsonParser.parseEnum(json, 'type', BadgeType.values, BadgeType.taskCompletion) ?? BadgeType.taskCompletion,
        familyId: JsonParser.parseString(json, 'familyId', defaultValue: '') ?? '',
        creatorId: JsonParser.parseString(json, 'creatorId'),
        createdAt: JsonParser.parseDateTime(json, 'createdAt') ?? DateTime.now(),
        updatedAt: JsonParser.parseDateTime(json, 'updatedAt') ?? DateTime.now(),
        rarity: JsonParser.parseEnum(json, 'rarity', BadgeRarity.values, BadgeRarity.common) ?? BadgeRarity.common,
      );
    }
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

  /// Alias for fromJson for backward compatibility
  factory Badge.fromMap(Map<String, dynamic> json) {
    return Badge.fromJson(json);
  }

  /// Factory method for creating badges from Firestore documents
  factory Badge.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return Badge.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
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
