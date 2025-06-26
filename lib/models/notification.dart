// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  Notification._({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification({
    required String id,
    required String userId,
    required String title,
    required String message,
    String? imageUrl,
    required bool isRead,
    required DateTime createdAt,
  }) {
    return Notification._(
      id: id,
      userId: userId,
      title: title,
      message: message,
      imageUrl: imageUrl,
      isRead: isRead,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['imageUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
                  DateTime.now(),
    );
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? imageUrl,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Notification &&
        other.id == id &&
        other.title == title &&
        other.message == message &&
        other.isRead == isRead &&
        other.createdAt == createdAt &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      message,
      isRead,
      createdAt,
      userId,
    );
  }

  /// Alias for fromJson for backward compatibility
  factory Notification.fromMap(Map<String, dynamic> json) {
    return Notification.fromJson(json);
  }

  /// Factory method for creating notifications from Firestore documents
  factory Notification.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return Notification.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
  }
}
