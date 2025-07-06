import 'package:equatable/equatable.dart';

/// Value object representing a user ID
class UserId extends Equatable {
  final String value;

  const UserId._(this.value);

  /// Factory constructor that validates the user ID
  factory UserId(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }
    return UserId._(userId.trim());
  }

  /// Creates a user ID from a string, returns null if invalid
  static UserId? tryCreate(String userId) {
    try {
      return UserId(userId);
    } catch (e) {
      return null;
    }
  }

  /// Check if the user ID is valid
  static bool isValid(String userId) {
    return userId.isNotEmpty;
  }

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
} 