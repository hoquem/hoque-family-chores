import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for deleting user profiles
class DeleteUserUseCase {
  final UserRepository _userRepository;

  DeleteUserUseCase(this._userRepository);

  /// Deletes a user profile by ID
  /// 
  /// [userId] - ID of the user to delete
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required UserId userId,
  }) async {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Delete the user
      await _userRepository.deleteUserProfile(userId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete user: $e'));
    }
  }
} 