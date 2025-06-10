// lib/models/notification.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class Notification {
  final String id;
  final String message;
  final String type; // e.g., 'task_completed', 'badge_awarded'
  final DateTime timestamp;
  final bool read;

  const Notification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.read = false,
  });

  factory Notification.fromMap(Map<String, dynamic> data) {
    return Notification(
      id: data['id'] as String? ?? '',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'read': read,
    };
  }

  Notification copyWith({String? id, String? message, String? type, DateTime? timestamp, bool? read}) {
    return Notification(
      id: id ?? this.id,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}