// lib/models/family.dart

class Family {
  final String id;
  final String name;
  final String description;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;

  Family._({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
  });

  factory Family({
    required String id,
    required String name,
    required String description,
    required String creatorId,
    required List<String> memberIds,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? photoUrl,
  }) {
    return Family._(
      id: id,
      name: name,
      description: description,
      creatorId: creatorId,
      memberIds: memberIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      photoUrl: photoUrl,
    );
  }

  // --- Convenience getter for backward compatibility ---
  List<String> get memberUserIds => memberIds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      creatorId: json['creatorId'] as String,
      memberIds: List<String>.from(json['memberIds'] ?? []),
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Alias for fromJson for backward compatibility
  factory Family.fromMap(Map<String, dynamic> json) {
    return Family.fromJson(json);
  }

  /// Factory method for creating families from Firestore documents
  factory Family.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return Family.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
  }

  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? photoUrl,
  }) {
    return Family(
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Family &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.creatorId == creatorId &&
        other.memberIds.length == memberIds.length &&
        other.memberIds.every((id) => memberIds.contains(id)) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      creatorId,
      Object.hashAll(memberIds),
      createdAt,
      updatedAt,
      photoUrl,
    );
  }
}
