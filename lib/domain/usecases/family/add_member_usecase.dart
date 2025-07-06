import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/family.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for adding a member to a family
class AddMemberUseCase {
  final FamilyRepository _familyRepository;

  AddMemberUseCase(this._familyRepository);

  /// Adds a user to a family
  /// 
  /// Parameters:
  /// [familyId] - ID of the family to add the member to
  /// [userId] - ID of the user to add
  /// 
  /// Returns [FamilyEntity] on success or [Failure] on error
  Future<Either<Failure, FamilyEntity>> call({
    required FamilyId familyId,
    required UserId userId,
  }) async {
    try {
      // Get the current family
      final family = await _familyRepository.getFamily(familyId);
      if (family == null) {
        return Left(NotFoundFailure('Family not found'));
      }

      // Check if user is already a member
      if (family.hasMember(userId)) {
        return Left(BusinessFailure('User is already a member of this family'));
      }

      // Add member to family
      await _familyRepository.addUserToFamily(familyId, userId);
      
      // Return updated family
      final updatedFamily = await _familyRepository.getFamily(familyId);
      return Right(updatedFamily!);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to add member to family: $e'));
    }
  }
} 