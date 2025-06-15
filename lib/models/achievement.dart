// lib/models/achievement.dart
import 'package:hoque_family_chores/models/enums.dart';

class Achievement {
  @override
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;
  final BadgeType type;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;

  Achievement._({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    required this.type,
    required this.createdAt,
    this.completedAt,
    this.completedBy,
  });

  factory Achievement({
    required String id,
    required String title,
    required String description,
    required int points,
    required String icon,
    required BadgeType type,
    required DateTime createdAt,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return Achievement._(
      id: id,
      title: title,
      description: description,
      points: points,
      icon: icon,
      type: type,
      createdAt: createdAt,
      completedAt: completedAt,
      completedBy: completedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'icon': icon,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
    };
  }

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      icon: json['icon'] as String,
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BadgeType.taskCompletion,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt:
          json['completedAt'] != null
              ? DateTime.parse(json['completedAt'] as String)
              : null,
      completedBy: json['completedBy'] as String?,
    );
  }

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? icon,
    BadgeType? type,
    DateTime? createdAt,
    DateTime? completedAt,
    String? completedBy,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Achievement &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.points == points &&
        other.icon == icon &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.completedAt == completedAt &&
        other.completedBy == completedBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      points,
      icon,
      type,
      createdAt,
      completedAt,
      completedBy,
    );
  }
}
