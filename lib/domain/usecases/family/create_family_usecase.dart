import 'package:dartz/dartz.dart' hide Task;
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/family.dart';
import '../../repositories/family_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Use case for creating a new family
class CreateFamilyUseCase {
  final FamilyRepository _familyRepository;

  CreateFamilyUseCase(this._familyRepository);

  /// Creates a new family with the creator as the first member
  /// 
  /// Parameters:
  /// [name] - Family name
  /// [description] - Family description (optional)
  /// [creatorId] - ID of the user creating the family
  /// [photoUrl] - Optional family photo URL
  /// 
  /// Returns [FamilyEntity] on success or [Failure] on error
  Future<Either<Failure, FamilyEntity>> call({
    required String name,
    String? description,
    required UserId creatorId,
    String? photoUrl,
  }) async {
    try {
      // Validate input
      final validationResult = _validateFamilyInput(
        name: name,
        description: description,
        creatorId: creatorId,
      );
      
      if (validationResult.isLeft()) {
        return validationResult.fold(
          (failure) => Left(failure),
          (_) => throw Exception('Unexpected success in validation'),
        );
      }

      // Create family entity
      final now = DateTime.now();
      final family = FamilyEntity(
        id: FamilyId(''), // Will be set by repository
        name: name.trim(),
        description: description?.trim() ?? '',
        creatorId: creatorId,
        memberIds: [creatorId], // Creator is the first member
        createdAt: now,
        updatedAt: now,
        photoUrl: photoUrl,
      );

      // Save family to repository
      await _familyRepository.createFamily(family);
      
      // Return the created family (repository should return it with proper ID)
      // For now, we'll return the family as created
      return Right(family);
    } catch (e) {
      return Left(ServerFailure('Failed to create family: $e'));
    }
  }

  /// Validates family input parameters
  Either<Failure, void> _validateFamilyInput({
    required String name,
    String? description,
    required UserId creatorId,
  }) {
    // Validate name
    if (name.trim().isEmpty) {
      return Left(ValidationFailure('Family name cannot be empty'));
    }
    if (name.trim().length > 100) {
      return Left(ValidationFailure('Family name cannot exceed 100 characters'));
    }

    // Validate description
    if (description != null && description.trim().length > 500) {
      return Left(ValidationFailure('Family description cannot exceed 500 characters'));
    }

    return const Right(null);
  }
} 