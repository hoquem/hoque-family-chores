import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/reward_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for redeeming a reward
class RedeemRewardUseCase {
  final RewardRepository _rewardRepository;
  final UserRepository _userRepository;

  RedeemRewardUseCase(this._rewardRepository, this._userRepository);

  /// Redeems a reward for a user
  /// 
  /// [familyId] - ID of the family the reward belongs to
  /// [userId] - ID of the user redeeming the reward
  /// [rewardId] - ID of the reward to redeem
  /// 
  /// Returns [User] (updated user with deducted points) on success or [Failure] on error
  Future<Either<Failure, User>> call({
    required FamilyId familyId,
    required UserId userId,
    required String rewardId,
  }) async {
    try {
      // Get the reward
      final rewards = await _rewardRepository.getRewards(familyId);
      final reward = rewards.where((r) => r.id == rewardId).firstOrNull;
      if (reward == null) {
        return Left(NotFoundFailure('Reward not found'));
      }

      // Check if reward is available
      if (!reward.isAvailable) {
        return Left(BusinessFailure('Reward is not available'));
      }

      // Get current user
      final currentUser = await _userRepository.getUserProfile(userId);
      if (currentUser == null) {
        return Left(NotFoundFailure('User not found'));
      }

      // Check if user can afford the reward
      if (!reward.canBeAfforded(currentUser.points)) {
        return Left(BusinessFailure('Insufficient points to redeem this reward'));
      }

      // Request redemption (creates pending request, doesn't deduct points yet)
      await _rewardRepository.requestRedemption(familyId, userId, rewardId);
      
      // Return updated user
      final updatedUser = await _userRepository.getUserProfile(userId);
      if (updatedUser == null) {
        return Left(ServerFailure('Failed to retrieve updated user'));
      }

      return Right(updatedUser);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to redeem reward: $e'));
    }
  }
} 