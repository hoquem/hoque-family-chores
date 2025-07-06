import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for removing members from families
class RemoveMemberUseCase {
  final FamilyRepository _familyRepository;

  RemoveMemberUseCase(this._familyRepository);

  /// Removes a member from a family
  /// 
  /// [familyId] - ID of the family
  /// [userId] - ID of the user to remove
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required UserId userId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Validate user ID
      if (userId.value.trim().isEmpty) {
        return Left(ValidationFailure('User ID cannot be empty'));
      }

      // Remove the member
      await _familyRepository.removeUserFromFamily(familyId, userId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to remove member: $e'));
    }
  }
} 