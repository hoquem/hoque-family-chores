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

      // Stream the user profile. Errors must be emitted as Left events —
      // handleError discards its callback's return value, which silently
      // swallowed failures and left listeners waiting forever.
      return _userRepository.streamUserProfile(userId).transform(
        StreamTransformer<User?, Either<Failure, User?>>.fromHandlers(
          handleData: (user, sink) => sink.add(Right(user)),
          handleError: (error, stackTrace, sink) {
            if (error is DataException) {
              sink.add(Left(ServerFailure(error.message, code: error.code)));
            } else {
              sink.add(
                Left(ServerFailure('Failed to stream user profile: $error')),
              );
            }
          },
        ),
      );
    } catch (e) {
      return Stream.value(Left(ServerFailure('Failed to stream user profile: $e')));
    }
  }
} 