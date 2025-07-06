import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for deleting families
class DeleteFamilyUseCase {
  final FamilyRepository _familyRepository;

  DeleteFamilyUseCase(this._familyRepository);

  /// Deletes a family by ID
  /// 
  /// [familyId] - ID of the family to delete
  /// 
  /// Returns [Unit] on success or [Failure] on error
  Future<Either<Failure, Unit>> call({
    required FamilyId familyId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Delete the family
      await _familyRepository.deleteFamily(familyId);
      return const Right(unit);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to delete family: $e'));
    }
  }
} 