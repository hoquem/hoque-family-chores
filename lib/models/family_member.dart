// lib/models/family_member.dart
// This acts as the base for UserProfile, containing common identity properties.

import 'package:hoque_family_chores/utils/json_parser.dart';
import 'package:hoque_family_chores/utils/logger.dart';

// --- Family-related Enums (co-located for encapsulation) ---
enum FamilyRole { parent, child, guardian, other }

class FamilyMember {
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

  // --- Convenience getters for backward compatibility ---
  String? get email => null; // FamilyMember doesn't store email, it's in UserProfile
  String? get avatarUrl => photoUrl;

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
    final logger = AppLogger();
    
    try {
      return FamilyMember(
        id: JsonParser.parseRequiredString(json, 'id'),
        userId: JsonParser.parseString(json, 'userId') ?? JsonParser.parseRequiredString(json, 'id'),
        familyId: JsonParser.parseString(json, 'familyId') ?? 'unknown',
        name: JsonParser.parseString(json, 'name') ?? 'Unknown User',
        photoUrl: JsonParser.parseString(json, 'photoUrl'),
        role: JsonParser.parseEnum(json, 'role', FamilyRole.values, FamilyRole.child) ?? FamilyRole.child,
        points: JsonParser.parseInt(json, 'points', defaultValue: 0) ?? 0,
        joinedAt: JsonParser.parseDateTime(json, 'joinedAt') ?? DateTime.now(),
        updatedAt: JsonParser.parseDateTime(json, 'updatedAt') ?? DateTime.now(),
      );
    } catch (e) {
      logger.e('Failed to parse FamilyMember from JSON: $e');
      logger.d('JSON data: $json');
      
      // Return a minimal valid family member with defaults
      return FamilyMember(
        id: JsonParser.parseString(json, 'id') ?? 'unknown-${DateTime.now().millisecondsSinceEpoch}',
        userId: JsonParser.parseString(json, 'userId') ?? JsonParser.parseString(json, 'id') ?? 'unknown-user',
        familyId: JsonParser.parseString(json, 'familyId') ?? 'unknown-family',
        name: JsonParser.parseString(json, 'name') ?? 'Unknown User',
        photoUrl: JsonParser.parseString(json, 'photoUrl'),
        role: JsonParser.parseEnum(json, 'role', FamilyRole.values, FamilyRole.child) ?? FamilyRole.child,
        points: JsonParser.parseInt(json, 'points', defaultValue: 0) ?? 0,
        joinedAt: JsonParser.parseDateTime(json, 'joinedAt') ?? DateTime.now(),
        updatedAt: JsonParser.parseDateTime(json, 'updatedAt') ?? DateTime.now(),
      );
    }
  }

  /// Alias for fromJson for backward compatibility
  factory FamilyMember.fromMap(Map<String, dynamic> json) {
    return FamilyMember.fromJson(json);
  }

  /// Factory method for creating family members from Firestore documents
  factory FamilyMember.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return FamilyMember.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
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
