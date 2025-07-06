/// Base class for all data layer exceptions
abstract class DataException implements Exception {
  final String message;
  final String? code;

  const DataException(this.message, {this.code});

  @override
  String toString() => 'DataException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Exception thrown when there's a server error
class ServerException extends DataException {
  const ServerException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when there's a network error
class NetworkException extends DataException {
  const NetworkException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when there's a cache error
class CacheException extends DataException {
  const CacheException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when authentication fails
class AuthException extends DataException {
  const AuthException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when validation fails
class ValidationException extends DataException {
  const ValidationException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when permission is denied
class PermissionException extends DataException {
  const PermissionException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when a resource is not found
class NotFoundException extends DataException {
  const NotFoundException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when there's a parsing error
class ParsingException extends DataException {
  const ParsingException(String message, {String? code}) : super(message, code: code);
}

/// Exception thrown when there's a Firebase-specific error
class FirebaseException extends DataException {
  const FirebaseException(String message, {String? code}) : super(message, code: code);
} 