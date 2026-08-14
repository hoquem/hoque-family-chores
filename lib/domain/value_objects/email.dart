import 'package:email_validator/email_validator.dart';
import 'package:equatable/equatable.dart';

/// Value object representing an email address
class Email extends Equatable {
  final String value;

  const Email._(this.value);

  /// Factory constructor that validates the email
  factory Email(String email) {
    // Trim before validating, not after: autofill and paste routinely leave a
    // trailing space, and surrounding whitespace does not make an address
    // malformed. The original string goes in the error so the user recognises
    // what they typed.
    final normalized = email.trim();
    // RFC 5322 syntax check via the maintained `email_validator` package
    // (pure Dart, so the domain layer stays Flutter-free). Deliberately no
    // deliverability check — that is the confirmation mail's job.
    if (!EmailValidator.validate(normalized)) {
      throw ArgumentError('Invalid email format: $email');
    }
    return Email._(normalized.toLowerCase());
  }

  /// Creates an email from a string, returns null if invalid
  static Email? tryCreate(String email) {
    try {
      return Email(email);
    } catch (e) {
      return null;
    }
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