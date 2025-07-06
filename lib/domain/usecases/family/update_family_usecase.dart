import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/family.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for updating family information
class UpdateFamilyUseCase {
  final FamilyRepository _familyRepository;

  UpdateFamilyUseCase(this._familyRepository);

  /// Updates family information
  /// 
  /// [family] - The family to update with new values
  /// 
  /// Returns [FamilyEntity] on success or [Failure] on error
  Future<Either<Failure, FamilyEntity>> call({
    required FamilyEntity family,
  }) async {
    try {
      // Validate family data
      if (family.name.trim().isEmpty) {
        return Left(ValidationFailure('Family name cannot be empty'));
      }

      // Update the family
      await _familyRepository.updateFamily(family);
      
      // Get the updated family to return
      final updatedFamily = await _familyRepository.getFamily(family.id);
      if (updatedFamily == null) {
        return Left(NotFoundFailure('Updated family not found'));
      }
      
      return Right(updatedFamily);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to update family: $e'));
    }
  }
} 