import 'dart:async';
import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for streaming user profile updates
class StreamUserProfileUseCase {
  final UserRepository _userRepository;

  StreamUserProfileUseCase(this._userRepository);

  /// Streams user profile updates
  /// 
  /// [userId] - ID of the user to stream profile for
  /// 
  /// Returns [Stream<User?>] on success or [Failure] on error
  Stream<Either<Failure, User?>> call({
    required UserId userId,
  }) {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Stream.value(Left(ValidationFailure('User ID cannot be empty')));
      }

      // Stream the user profile
      return _userRepository.streamUserProfile(userId).map(
        (user) => Right<Failure, User?>(user),
      ).handleError(
        (error) {
          if (error is DataException) {
            return Left<Failure, User?>(ServerFailure(error.message, code: error.code));
          }
          return Left<Failure, User?>(ServerFailure('Failed to stream user profile: $error'));
        },
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to stream user profile: $e')));
    }
  }
} 