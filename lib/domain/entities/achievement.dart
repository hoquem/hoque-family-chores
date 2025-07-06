import 'package:equatable/equatable.dart';
import '../value_objects/points.dart';
import 'badge.dart';

/// Domain entity representing an achievement
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final Points points;
  final String icon;
  final BadgeType type;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? completedBy;

  const Achievement({
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

  /// Creates a copy of this achievement with updated fields
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    Points? points,
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

  /// Check if achievement is completed
  bool get isCompleted => completedAt != null;

  /// Check if achievement is completed by a specific user
  bool isCompletedBy(String userId) {
    return completedBy == userId;
  }

  /// Mark achievement as completed by a user
  Achievement markAsCompleted(String userId) {
    if (isCompleted) {
      return this; // Already completed
    }
    return copyWith(
      completedAt: DateTime.now(),
      completedBy: userId,
    );
  }

  /// Unmark achievement as completed
  Achievement unmarkAsCompleted() {
    if (!isCompleted) {
      return this; // Not completed
    }
    return copyWith(
      completedAt: null,
      completedBy: null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        points,
        icon,
        type,
        createdAt,
        completedAt,
        completedBy,
      ];
} 