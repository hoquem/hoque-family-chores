import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

enum FamilyRole {
  parent,
  child,
  guardian,
  other,
}

class FamilyMember {
  final UserId userId;
  final FamilyId familyId;
  final String name;
  final String? photoUrl;
  final FamilyRole role;
  final DateTime joinedAt;
  final bool isActive;

  const FamilyMember({
    required this.userId,
    required this.familyId,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMember &&
        other.userId == userId &&
        other.familyId == familyId &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.role == role &&
        other.joinedAt == joinedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        familyId.hashCode ^
        name.hashCode ^
        photoUrl.hashCode ^
        role.hashCode ^
        joinedAt.hashCode ^
        isActive.hashCode;
  }

  @override
  String toString() {
    return 'FamilyMember(userId: $userId, familyId: $familyId, name: $name, role: $role, joinedAt: $joinedAt, isActive: $isActive)';
  }
} 