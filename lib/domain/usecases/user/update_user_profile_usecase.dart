import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/email.dart';

/// Use case for updating user profile
class UpdateUserProfileUseCase {
  final UserRepository _userRepository;

  UpdateUserProfileUseCase(this._userRepository);

  /// Updates a user profile
  /// 
  /// [userId] - ID of the user to update
  /// [name] - New name (optional)
  /// [email] - New email (optional)
  /// [photoUrl] - New photo URL (optional)
  /// 
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> call({
    required UserId userId,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      // Get current user
      final currentUser = await _userRepository.getUserProfile(userId);
      if (currentUser == null) {
        return Left(NotFoundFailure('User not found'));
      }

      // Validate input parameters
      final validationResult = _validateUpdateInput(
        name: name,
        email: email,
      );
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((failure) => failure, (_) => throw Exception('Unexpected')));
      }

      // Create updated user
      final updatedUser = currentUser.copyWith(
        name: name?.trim() ?? currentUser.name,
        email: email != null ? Email(email.trim().toLowerCase()) : currentUser.email,
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );

      // Update user in repository
      await _userRepository.updateUserProfile(updatedUser);
      
      // Return updated user
      final result = await _userRepository.getUserProfile(userId);
      if (result == null) {
        return Left(ServerFailure('Failed to retrieve updated user'));
      }

      return Right(result);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to update user profile: $e'));
    }
  }

  /// Validates update input parameters
  Either<Failure, void> _validateUpdateInput({
    String? name,
    String? email,
  }) {
    // Validate name
    if (name != null && name.trim().isNotEmpty) {
      if (name.trim().length < 2) {
        return Left(ValidationFailure('Name must be at least 2 characters'));
      }
      if (name.trim().length > 50) {
        return Left(ValidationFailure('Name cannot exceed 50 characters'));
      }
    }

    // Validate email
    if (email != null && email.trim().isNotEmpty) {
      try {
        Email(email.trim().toLowerCase());
      } catch (e) {
        return Left(ValidationFailure('Invalid email format'));
      }
    }

    return const Right(null);
  }
} 