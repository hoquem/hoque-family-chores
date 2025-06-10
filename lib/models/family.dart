// lib/models/family.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String? description;
  final String creatorUserId;
  final DateTime createdAt;
  final String? photoUrl;
  final List<String> memberUserIds; // List of UIDs for members

  const Family({
    required this.id,
    required this.name,
    this.description,
    required this.creatorUserId,
    required this.createdAt,
    this.photoUrl,
    this.memberUserIds = const [],
  });

  factory Family.fromMap(Map<String, dynamic> map, String id) {
    return Family(
      id: id,
      name: map['name'] as String? ?? 'Unnamed Family',
      description: map['description'] as String?,
      creatorUserId: map['creatorUserId'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: map['photoUrl'] as String?,
      memberUserIds: List<String>.from(map['memberUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'creatorUserId': creatorUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'photoUrl': photoUrl,
      'memberUserIds': memberUserIds,
    };
  }

  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorUserId,
    DateTime? createdAt,
    String? photoUrl,
    List<String>? memberUserIds,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorUserId: creatorUserId ?? this.creatorUserId,
      createdAt: createdAt ?? this.createdAt,
      photoUrl: photoUrl ?? this.photoUrl,
      memberUserIds: memberUserIds ?? this.memberUserIds,
    );
  }
}