import 'package:equatable/equatable.dart';

/// Abstract base class for all domain failures
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Represents a server failure
class ServerFailure extends Failure {
  const ServerFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a network failure
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a cache failure
class CacheFailure extends Failure {
  const CacheFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents an authentication failure
class AuthFailure extends Failure {
  const AuthFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a validation failure
class ValidationFailure extends Failure {
  const ValidationFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a permission failure
class PermissionFailure extends Failure {
  const PermissionFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure(String message, {String? code}) : super(message, code: code);
}

/// Represents a business logic failure
class BusinessFailure extends Failure {
  const BusinessFailure(String message, {String? code}) : super(message, code: code);
} 