import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/leaderboard_entry.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting all-time leaderboard data
/// 
/// Shows lifetime statistics: total stars, quests completed, longest streak, weekly wins
class GetAllTimeLeaderboardUseCase {
  final LeaderboardRepository _leaderboardRepository;

  GetAllTimeLeaderboardUseCase(this._leaderboardRepository);

  /// Gets all-time leaderboard entries for a family
  /// 
  /// [familyId] - ID of the family to get leaderboard for
  /// 
  /// Returns [List<LeaderboardEntry>] on success or [Failure] on error
  Future<Either<Failure, List<LeaderboardEntry>>> call({
    required FamilyId familyId,
  }) async {
    try {
      final entries = await _leaderboardRepository.getAllTimeLeaderboard(familyId);
      
      // Entries are pre-sorted by total stars descending
      return Right(entries);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get all-time leaderboard: $e'));
    }
  }
}
