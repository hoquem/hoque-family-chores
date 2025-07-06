import 'failures.dart';
import 'exceptions.dart';

/// Centralized error handler that converts data exceptions to domain failures
class ErrorHandler {
  /// Converts a data exception to a domain failure
  static Failure handleException(dynamic exception) {
    if (exception is DataException) {
      return _convertDataExceptionToFailure(exception);
    }
    
    // Handle unexpected exceptions
    return ServerFailure(
      exception?.toString() ?? 'An unexpected error occurred',
      code: 'UNKNOWN_ERROR',
    );
  }

  /// Converts specific data exceptions to domain failures
  static Failure _convertDataExceptionToFailure(DataException exception) {
    switch (exception.runtimeType) {
      case ServerException:
        return ServerFailure(exception.message, code: exception.code);
      case NetworkException:
        return NetworkFailure(exception.message, code: exception.code);
      case CacheException:
        return CacheFailure(exception.message, code: exception.code);
      case AuthException:
        return AuthFailure(exception.message, code: exception.code);
      case ValidationException:
        return ValidationFailure(exception.message, code: exception.code);
      case PermissionException:
        return PermissionFailure(exception.message, code: exception.code);
      case NotFoundException:
        return NotFoundFailure(exception.message, code: exception.code);
      case FirebaseException:
        return ServerFailure(exception.message, code: exception.code);
      default:
        return ServerFailure(exception.message, code: exception.code);
    }
  }

  /// Creates a failure from a Firebase error
  static Failure handleFirebaseError(dynamic error) {
    if (error is Exception) {
      return ServerFailure(
        error.toString(),
        code: 'FIREBASE_ERROR',
      );
    }
    return ServerFailure(
      'Firebase operation failed',
      code: 'FIREBASE_ERROR',
    );
  }

  /// Creates a failure from a network error
  static Failure handleNetworkError(dynamic error) {
    return NetworkFailure(
      'Network operation failed: ${error?.toString() ?? 'Unknown error'}',
      code: 'NETWORK_ERROR',
    );
  }

  /// Creates a validation failure
  static Failure handleValidationError(String message, {String? code}) {
    return ValidationFailure(message, code: code);
  }

  /// Creates a business logic failure
  static Failure handleBusinessError(String message, {String? code}) {
    return BusinessFailure(message, code: code);
  }
} 