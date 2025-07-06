import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting leaderboard data
class GetLeaderboardUseCase {
  final LeaderboardRepository _leaderboardRepository;

  GetLeaderboardUseCase(this._leaderboardRepository);

  /// Gets leaderboard entries for a family
  /// 
  /// [familyId] - ID of the family to get leaderboard for
  /// 
  /// Returns [List<User>] on success or [Failure] on error
  Future<Either<Failure, List<User>>> call({
    required FamilyId familyId,
  }) async {
    try {
      final leaderboard = await _leaderboardRepository.getLeaderboard(familyId);
      
      // Sort by points in descending order
      final sortedLeaderboard = List<User>.from(leaderboard)
        ..sort((a, b) => b.points.toInt().compareTo(a.points.toInt()));
      
      return Right(sortedLeaderboard);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get leaderboard: $e'));
    }
  }

  /// Gets top N users from leaderboard
  /// 
  /// [familyId] - ID of the family to get leaderboard for
  /// [limit] - Number of top users to return
  /// 
  /// Returns [List<User>] on success or [Failure] on error
  Future<Either<Failure, List<User>>> getTopUsers({
    required FamilyId familyId,
    int limit = 10,
  }) async {
    try {
      final result = await call(familyId: familyId);
      return result.map((users) => users.take(limit).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to get top users: $e'));
    }
  }
} 