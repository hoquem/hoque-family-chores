import 'package:equatable/equatable.dart';

/// Value object representing an email address
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  /// Factory constructor that validates the email
  factory Email(String email) {
    if (!_isValidEmail(email)) {
      throw ArgumentError('Invalid email format: $email');
    }
    return Email._(email.toLowerCase().trim());
  }

  /// Creates an email from a string, returns null if invalid
  static Email? tryCreate(String email) {
    try {
      return Email(email);
    } catch (e) {
      return null;
    }
  }

  /// Validates email format using a simple regex
  static bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Simple email validation regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    return emailRegex.hasMatch(email);
  }

  /// Returns the local part of the email (before @)
  String get localPart => value.split('@').first;

  /// Returns the domain part of the email (after @)
  String get domain => value.split('@').last;

  @override
  List<Object> get props => [value];

  @override
  String toString() => value;
} 