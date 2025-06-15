// lib/models/family_member.dart
// This acts as the base for UserProfile, containing common identity properties.
// <--- NEW: Import enum_helpers

class FamilyMember {
  @override
  final String id;
  final String userId;
  final String familyId;
  final String name;
  final String? photoUrl;
  final FamilyRole role;
  final int points;
  final DateTime joinedAt;
  final DateTime updatedAt;

  FamilyMember._({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.name,
    this.photoUrl,
    required this.role,
    required this.points,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory FamilyMember({
    required String id,
    required String userId,
    required String familyId,
    required String name,
    String? photoUrl,
    required FamilyRole role,
    required int points,
    required DateTime joinedAt,
    required DateTime updatedAt,
  }) {
    return FamilyMember._(
      id: id,
      userId: userId,
      familyId: familyId,
      name: name,
      photoUrl: photoUrl,
      role: role,
      points: points,
      joinedAt: joinedAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.name,
      'points': points,
      'joinedAt': joinedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: FamilyRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => FamilyRole.child,
      ),
      points: json['points'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? name,
    String? photoUrl,
    FamilyRole? role,
    int? points,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      points: points ?? this.points,
      joinedAt: joinedAt ?? this.joinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FamilyMember &&
        other.id == id &&
        other.userId == userId &&
        other.familyId == familyId &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.role == role &&
        other.points == points &&
        other.joinedAt == joinedAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      familyId,
      name,
      photoUrl,
      role,
      points,
      joinedAt,
      updatedAt,
    );
  }
}

// --- FamilyRole Enum (kept in this file for encapsulation) ---
enum FamilyRole { parent, child, guardian, other }
