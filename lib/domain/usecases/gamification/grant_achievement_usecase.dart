import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/achievement.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/family_id.dart';

/// Use case for granting achievements to users
class GrantAchievementUseCase {
  final AchievementRepository _achievementRepository;
  final UserRepository _userRepository;

  GrantAchievementUseCase(this._achievementRepository, this._userRepository);

  /// Grants an achievement to a user
  /// 
  /// [userId] - ID of the user to grant the achievement to
  /// [achievement] - The achievement to grant
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required UserId userId,
    required Achievement achievement,
  }) async {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Validate achievement
      if (achievement.id == null) {
        return Left(ValidationFailure('Achievement ID cannot be empty'));
      }

      if (achievement.title.trim().isEmpty) {
        return Left(ValidationFailure('Achievement title cannot be empty'));
      }

      // Grant the achievement
      await _achievementRepository.grantAchievement(userId, achievement);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to grant achievement: $e'));
    }
  }
} 