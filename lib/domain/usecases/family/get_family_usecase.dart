import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/family.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for getting family details
class GetFamilyUseCase {
  final FamilyRepository _familyRepository;

  GetFamilyUseCase(this._familyRepository);

  /// Gets family details by ID
  /// 
  /// [familyId] - ID of the family to get
  /// 
  /// Returns [FamilyEntity] on success or [Failure] on error
  Future<Either<Failure, FamilyEntity>> call({
    required FamilyId familyId,
  }) async {
    try {
      // Validate family ID
      if (familyId.value.trim().isEmpty) {
        return Left(ValidationFailure('Family ID cannot be empty'));
      }

      // Get the family
      final family = await _familyRepository.getFamily(familyId);
      if (family == null) {
        return Left(NotFoundFailure('Family not found'));
      }

      return Right(family);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to get family: $e'));
    }
  }
} 