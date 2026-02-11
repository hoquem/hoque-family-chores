import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/streak.dart';
import '../../repositories/streak_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/points.dart';

/// Use case for updating user streak after quest completion
class UpdateStreakUseCase {
  final StreakRepository _streakRepository;
  final UserRepository _userRepository;

  UpdateStreakUseCase(this._streakRepository, this._userRepository);

  /// Updates streak after a quest completion
  /// 
  /// [userId] - ID of the user who completed the quest
  /// [completionDate] - Date/time when the quest was completed
  /// 
  /// Returns updated [Streak] with milestone info on success or [Failure] on error
  Future<Either<Failure, StreakUpdateResult>> call({
    required UserId userId,
    required DateTime completionDate,
  }) async {
    try {
      // Get current streak or create if doesn't exist
      final currentStreak = await _streakRepository.getStreak(userId);
      final streak = currentStreak ?? Streak.initial(userId);

      // Check if this is the first quest ever
      if (streak.lastCompletedDate == null) {
        final updatedStreak = await _streakRepository.incrementStreak(userId, completionDate);
        return Right(StreakUpdateResult(
          streak: updatedStreak,
          milestoneReached: null,
          streakIncremented: true,
        ));
      }

      // Check if already completed a quest today
      final lastDate = streak.lastCompletedDate!;
      if (_isSameDay(lastDate, completionDate)) {
        // No change - already counted for today
        return Right(StreakUpdateResult(
          streak: streak,
          milestoneReached: null,
          streakIncremented: false,
        ));
      }

      // Check if it's consecutive days
      final yesterday = DateTime(
        completionDate.year,
        completionDate.month,
        completionDate.day - 1,
      );

      if (_isSameDay(lastDate, yesterday)) {
        // Consecutive day - increment streak
        final updatedStreak = await _streakRepository.incrementStreak(userId, completionDate);
        
        // Check for milestone achievement
        final milestone = StreakMilestone.forDays(updatedStreak.currentStreak);
        if (milestone != null && !updatedStreak.hasMilestone(milestone.days)) {
          // Award milestone bonus
          await _streakRepository.awardMilestoneBonus(
            userId,
            milestone.days,
            milestone.starReward,
          );
          await _userRepository.addPoints(
            userId,
            Points(milestone.starReward),
          );

          return Right(StreakUpdateResult(
            streak: updatedStreak.copyWith(
              milestonesAchieved: [...updatedStreak.milestonesAchieved, milestone.days],
            ),
            milestoneReached: milestone,
            streakIncremented: true,
          ));
        }

        return Right(StreakUpdateResult(
          streak: updatedStreak,
          milestoneReached: null,
          streakIncremented: true,
        ));
      } else {
        // Missed day(s) - check if freeze available
        if (streak.freezesAvailable > 0) {
          // Auto-use freeze to save streak
          final updatedStreak = await _streakRepository.useFreeze(userId);
          return Right(StreakUpdateResult(
            streak: updatedStreak,
            milestoneReached: null,
            streakIncremented: false,
            freezeUsed: true,
          ));
        } else {
          // No freeze - reset streak and start fresh
          await _streakRepository.resetStreak(userId);
          final newStreak = await _streakRepository.incrementStreak(userId, completionDate);
          
          return Right(StreakUpdateResult(
            streak: newStreak,
            milestoneReached: null,
            streakIncremented: true,
            streakBroken: true,
            previousStreak: streak.currentStreak,
          ));
        }
      }
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to update streak: $e'));
    }
  }

  /// Helper to check if two dates are the same calendar day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// Result of a streak update operation
class StreakUpdateResult {
  final Streak streak;
  final StreakMilestone? milestoneReached;
  final bool streakIncremented;
  final bool freezeUsed;
  final bool streakBroken;
  final int? previousStreak;

  const StreakUpdateResult({
    required this.streak,
    this.milestoneReached,
    required this.streakIncremented,
    this.freezeUsed = false,
    this.streakBroken = false,
    this.previousStreak,
  });
}
