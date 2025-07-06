import 'package:equatable/equatable.dart';

/// Domain entity representing a notification
class Notification extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  /// Creates a copy of this notification with updated fields
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

  /// Mark notification as read
  Notification markAsRead() {
    return copyWith(isRead: true);
  }

  /// Mark notification as unread
  Notification markAsUnread() {
    return copyWith(isRead: false);
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        imageUrl,
        isRead,
        createdAt,
      ];
} 