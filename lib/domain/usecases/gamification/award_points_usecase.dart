import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/points.dart';

/// Use case for awarding points to a user
class AwardPointsUseCase {
  final UserRepository _userRepository;

  AwardPointsUseCase(this._userRepository);

  /// Awards points to a user
  /// 
  /// [userId] - ID of the user to award points to
  /// [points] - Number of points to award
  /// [reason] - Reason for awarding points (optional)
  /// 
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> call({
    required UserId userId,
    required int points,
    String? reason,
  }) async {
    try {
      // Validate input parameters
      final validationResult = _validatePointsInput(points: points);
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((failure) => failure, (_) => throw Exception('Unexpected')));
      }

      // Get current user
      final currentUser = await _userRepository.getUserProfile(userId);
      if (currentUser == null) {
        return Left(NotFoundFailure('User not found'));
      }

      // Calculate new points
      final pointsToAdd = Points(points);
      final newPoints = currentUser.points.add(pointsToAdd);

      // Update user points
      await _userRepository.updateUserPoints(userId, newPoints);
      
      // Return updated user
      final updatedUser = await _userRepository.getUserProfile(userId);
      if (updatedUser == null) {
        return Left(ServerFailure('Failed to retrieve updated user'));
      }

      return Right(updatedUser);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to award points: $e'));
    }
  }

  /// Validates points input
  Either<Failure, void> _validatePointsInput({
    required int points,
  }) {
    // Validate points
    if (points <= 0) {
      return Left(ValidationFailure('Points must be positive'));
    }
    if (points > 10000) {
      return Left(ValidationFailure('Cannot award more than 10,000 points at once'));
    }

    return const Right(null);
  }
} 