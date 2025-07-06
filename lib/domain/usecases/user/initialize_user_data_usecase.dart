import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/user_id.dart';
import '../../value_objects/points.dart';
import '../../value_objects/email.dart';
import '../../value_objects/family_id.dart';

/// Use case for initializing user data
class InitializeUserDataUseCase {
  final UserRepository _userRepository;

  InitializeUserDataUseCase(this._userRepository);

  /// Initializes user data with default values
  /// 
  /// [userId] - ID of the user to initialize
  /// [name] - Name of the user
  /// [email] - Email of the user
  /// 
  /// Returns [User] on success or [Failure] on error
  Future<Either<Failure, User>> call({
    required UserId userId,
    required String name,
    required String email,
  }) async {
    try {
      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Validate name
      if (name.trim().isEmpty) {
        return Left(ValidationFailure('User name cannot be empty'));
      }

      // Validate email
      if (email.trim().isEmpty) {
        return Left(ValidationFailure('User email cannot be empty'));
      }

      // Create user with default values
      final user = User(
        id: userId,
        name: name,
        email: Email(email),
        familyId: FamilyId(''), // Will be set when user joins a family
        role: UserRole.child, // Default role
        points: Points(0),
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create the user profile
      await _userRepository.createUserProfile(user);
      return Right(user);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to initialize user data: $e'));
    }
  }
} 