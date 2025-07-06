import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';

/// Use case for getting user profile
class GetUserProfileUseCase {
  final UserRepository _userRepository;

  GetUserProfileUseCase(this._userRepository);

  /// Gets a user profile by ID
  /// 
  /// [userId] - ID of the user to get profile for
  /// 
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> call({
    required UserId userId,
  }) async {
    try {
      final user = await _userRepository.getUserProfile(userId);
      if (user == null) {
        return Left(NotFoundFailure('User not found'));
      }
      return Right(user);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get user profile: $e'));
    }
  }
} 