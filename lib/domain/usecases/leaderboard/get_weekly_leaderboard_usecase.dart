import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/leaderboard_entry.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting weekly leaderboard data
/// 
/// Queries stars earned this week (Monday-Sunday) and ranks family members.
/// Applies tiebreaker rules: most quests → longest streak → alphabetical
class GetWeeklyLeaderboardUseCase {
  final LeaderboardRepository _leaderboardRepository;

  GetWeeklyLeaderboardUseCase(this._leaderboardRepository);

  /// Gets weekly leaderboard entries for a family
  /// 
  /// [familyId] - ID of the family to get leaderboard for
  /// 
  /// Returns [List<LeaderboardEntry>] on success or [Failure] on error
  Future<Either<Failure, List<LeaderboardEntry>>> call({
    required FamilyId familyId,
  }) async {
    try {
      final entries = await _leaderboardRepository.getWeeklyLeaderboard(familyId);
      
      // Entries are pre-sorted by repository with tiebreaker rules applied
      // Rank is already assigned
      return Right(entries);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get weekly leaderboard: $e'));
    }
  }

  /// Gets current week start date (Monday at 00:00)
  DateTime getWeekStart() {
    return _leaderboardRepository.getCurrentWeekStart();
  }

  /// Gets current week end date (Sunday at 23:59)
  DateTime getWeekEnd() {
    return _leaderboardRepository.getCurrentWeekEnd();
  }
  
  /// Gets top N users from weekly leaderboard
  /// 
  /// [familyId] - ID of the family to get leaderboard for
  /// [limit] - Number of top users to return (default: 3 for podium)
  /// 
  /// Returns [List<LeaderboardEntry>] on success or [Failure] on error
  Future<Either<Failure, List<LeaderboardEntry>>> getTopUsers({
    required FamilyId familyId,
    int limit = 3,
  }) async {
    try {
      final result = await call(familyId: familyId);
      return result.map((entries) => entries.take(limit).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to get top users: $e'));
    }
  }
}
