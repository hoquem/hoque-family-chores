// lib/models/family_member.dart
// This acts as the base for UserProfile, containing common identity properties.
import 'package:hoque_family_chores/models/enums.dart'; // For FamilyRole
import 'package:hoque_family_chores/utils/enum_helpers.dart'; // <--- NEW: Import enum_helpers

class FamilyMember {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final FamilyRole? role;
  final String? familyId;

  const FamilyMember({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    this.role,
    this.familyId,
  });

  // Basic fromMap for FamilyMember
  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    try {
      final role = enumFromString(
        map['role'] as String?,
        FamilyRole.values,
        defaultValue: FamilyRole.child,
      );
      return FamilyMember(
        id: (map['id'] ?? map['uid'] ?? '').toString(),
        name: (map['name'] as String?)?.trim() ?? 'No Name',
        email: map['email'] as String?,
        avatarUrl: map['avatarUrl'] as String?,
        role: role,
        familyId: map['familyId'] as String?,
      );
    } catch (e) {
      print('Error parsing FamilyMember.fromMap: $e');
      return FamilyMember(id: '', name: 'Unknown');
    }
  }

  // Basic toJson for FamilyMember
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'role': role?.name,
      'familyId': familyId,
    };
  }

  // Add copyWith for convenience in extending classes or updates
  FamilyMember copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    FamilyRole? role,
    String? familyId,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMember &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
