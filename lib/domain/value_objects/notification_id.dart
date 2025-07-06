import 'package:equatable/equatable.dart';

/// Value object representing a notification ID
class NotificationId extends Equatable {
  final String value;

  const NotificationId._(this.value);

  /// Factory constructor that validates the notification ID
  factory NotificationId(String notificationId) {
    if (notificationId.isEmpty) {
      throw ArgumentError('Notification ID cannot be empty');
    }
    return NotificationId._(notificationId.trim());
  }

  /// Creates a notification ID from a string, returns null if invalid
  static NotificationId? tryCreate(String notificationId) {
    try {
      return NotificationId(notificationId);
    } catch (e) {
      return null;
    }
  }

  /// Check if the notification ID is valid
  static bool isValid(String notificationId) {
    return notificationId.isNotEmpty;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
} 