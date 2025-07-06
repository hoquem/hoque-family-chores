import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for updating family members
class UpdateFamilyMemberUseCase {
  final FamilyRepository _familyRepository;

  UpdateFamilyMemberUseCase(this._familyRepository);

  /// Updates a family member
  /// 
  /// [familyId] - ID of the family
  /// [memberId] - ID of the member to update
  /// [member] - Updated member data
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
    required UserId memberId,
    required User member,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Validate member ID
      if (memberId.value.trim().isEmpty) {
        return Left(ValidationFailure('Member ID cannot be empty'));
      }

      // Validate member data
      if (member.name.trim().isEmpty) {
        return Left(ValidationFailure('Member name cannot be empty'));
      }

      // Update the family member
      await _familyRepository.updateFamilyMember(familyId, memberId, member);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to update family member: $e'));
    }
  }
} 