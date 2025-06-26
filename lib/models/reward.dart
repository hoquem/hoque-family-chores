// lib/models/reward.dart
import 'package:flutter/material.dart';

class Reward {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String iconName;
  final RewardType type;
  final String familyId;
  final String? creatorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final RewardRarity rarity;

  Reward._({
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

  factory Reward({
    required String id,
    required String name,
    required String description,
    required int pointsCost,
    required String iconName,
    required RewardType type,
    required String familyId,
    String? creatorId,
    required DateTime createdAt,
    required DateTime updatedAt,
    RewardRarity rarity = RewardRarity.common,
  }) {
    return Reward._(
      id: id,
      name: name,
      description: description,
      pointsCost: pointsCost,
      iconName: iconName,
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
      'pointsCost': pointsCost,
      'iconName': iconName,
      'type': type.name,
      'familyId': familyId,
      'creatorId': creatorId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rarity': rarity.name,
    };
  }

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      pointsCost: json['pointsCost'] as int? ?? 0,
      iconName: json['iconName'] ?? 'card_giftcard',
      type: RewardType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RewardType.digital,
      ),
      familyId: json['familyId'] ?? '',
      creatorId: json['creatorId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rarity: RewardRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => RewardRarity.common,
      ),
    );
  }

  Reward copyWith({
    String? id,
    String? name,
    String? description,
    int? pointsCost,
    String? iconName,
    RewardType? type,
    String? familyId,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reward &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.pointsCost == pointsCost &&
        other.iconName == iconName &&
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
      pointsCost,
      iconName,
      type,
      familyId,
      creatorId,
      createdAt,
      updatedAt,
      rarity,
    );
  }

  String get title => name;

  // --- Convenience getters for backward compatibility ---
  bool get isAvailable => true; // Default to available, can be overridden

  /// Alias for fromJson for backward compatibility
  factory Reward.fromMap(Map<String, dynamic> json) {
    return Reward.fromJson(json);
  }

  /// Factory method for creating rewards from Firestore documents
  factory Reward.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return Reward.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
  }
}

// --- Reward-related Enums (kept in this file for encapsulation) ---
enum RewardCategory {
  digital(displayName: 'Digital'),
  physical(displayName: 'Physical'),
  privilege(displayName: 'Privilege');

  const RewardCategory({required this.displayName});
  final String displayName;
}

enum RewardType { digital, physical, privilege }

enum RewardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  Color get color {
    switch (this) {
      case RewardRarity.common:
        return Colors.green;
      case RewardRarity.uncommon:
        return Colors.cyan;
      case RewardRarity.rare:
        return Colors.deepOrange;
      case RewardRarity.epic:
        return Colors.purpleAccent;
      case RewardRarity.legendary:
        return Colors.amber;
    }
  }
}
