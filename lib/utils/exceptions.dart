// lib/utils/exceptions.dart

/// A base class for all custom exceptions in the app.
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Represents an exception related to authentication.
class AuthException extends AppException {
  AuthException(super.message);
}