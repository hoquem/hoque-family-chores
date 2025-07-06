import 'package:equatable/equatable.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// Domain entity representing a family
class FamilyEntity extends Equatable {
  final FamilyId id;
  final String name;
  final String description;
  final UserId creatorId;
  final List<UserId> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;

  const FamilyEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
  });

  /// Creates a copy of this family with updated fields
  FamilyEntity copyWith({
    FamilyId? id,
    String? name,
    String? description,
    UserId? creatorId,
    List<UserId>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? photoUrl,
  }) {
    return FamilyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Check if a user is a member of this family
  bool hasMember(UserId userId) {
    return memberIds.contains(userId);
  }

  /// Check if a user is the creator of this family
  bool isCreatedBy(UserId userId) {
    return creatorId == userId;
  }

  /// Get the number of members in the family
  int get memberCount => memberIds.length;

  /// Check if family has any members
  bool get hasMembers => memberIds.isNotEmpty;

  /// Check if family is empty (no members)
  bool get isEmpty => memberIds.isEmpty;

  /// Add a member to the family
  FamilyEntity addMember(UserId userId) {
    if (hasMember(userId)) {
      return this; // Already a member
    }
    return copyWith(
      memberIds: [...memberIds, userId],
      updatedAt: DateTime.now(),
    );
  }

  /// Remove a member from the family
  FamilyEntity removeMember(UserId userId) {
    if (!hasMember(userId)) {
      return this; // Not a member
    }
    return copyWith(
      memberIds: memberIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        creatorId,
        memberIds,
        createdAt,
        updatedAt,
        photoUrl,
      ];
} 