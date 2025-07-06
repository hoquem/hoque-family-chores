import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/user.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting family members
class GetFamilyMembersUseCase {
  final FamilyRepository _familyRepository;

  GetFamilyMembersUseCase(this._familyRepository);

  /// Gets all members of a family
  /// 
  /// [familyId] - ID of the family to get members for
  /// 
  /// Returns [List<User>] on success or [Failure] on error
  Future<Either<Failure, List<User>>> call({
    required FamilyId familyId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Get the family members
      final members = await _familyRepository.getFamilyMembers(familyId);
      return Right(members);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get family members: $e'));
    }
  }
} 