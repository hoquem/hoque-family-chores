import 'package:equatable/equatable.dart';
import '../value_objects/user_id.dart';
import '../value_objects/email.dart';
import '../value_objects/points.dart';
import '../value_objects/family_id.dart';

/// Domain entity representing a user
class User extends Equatable {
  final UserId id;
  final String name;
  final Email email;
  final String? photoUrl;
  final FamilyId familyId;
  final UserRole role;
  final Points points;
  final DateTime joinedAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.familyId,
    required this.role,
    required this.points,
    required this.joinedAt,
    required this.updatedAt,
  });

  /// Creates a copy of this user with updated fields
  User copyWith({
    UserId? id,
    String? name,
    Email? email,
    String? photoUrl,
    FamilyId? familyId,
    UserRole? role,
    Points? points,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      familyId: familyId ?? this.familyId,
      role: role ?? this.role,
      points: points ?? this.points,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is a parent
  bool get isParent => role == UserRole.parent;

  /// Check if user is a child
  bool get isChild => role == UserRole.child;

  /// Check if user is a guardian
  bool get isGuardian => role == UserRole.guardian;

  /// Check if user has any points
  bool get hasPoints => points.isPositive;

  /// Check if user has zero points
  bool get hasNoPoints => points.isZero;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        familyId,
        role,
        points,
        joinedAt,
        updatedAt,
      ];
}

/// User roles in the family system
enum UserRole {
  parent,
  child,
  guardian,
  other;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.parent:
        return 'Parent';
      case UserRole.child:
        return 'Child';
      case UserRole.guardian:
        return 'Guardian';
      case UserRole.other:
        return 'Other';
    }
  }

  /// Check if role has admin privileges
  bool get isAdmin => this == UserRole.parent || this == UserRole.guardian;
} 