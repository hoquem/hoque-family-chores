import 'dart:math';

import 'package:dartz/dartz.dart' hide Task;
import 'package:uuid/uuid.dart';
import '../../../core/error/failures.dart';
import '../../entities/family.dart';
import '../../repositories/family_repository.dart';
import '../../repositories/user_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';
import '../../entities/user.dart';

/// Use case for creating a new family
class CreateFamilyUseCase {
  final FamilyRepository _familyRepository;
  final UserRepository _userRepository;

  CreateFamilyUseCase(this._familyRepository, this._userRepository);

  /// Characters used for invite codes; ambiguous glyphs (0/O, 1/I/L) excluded.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Creates a new family with the creator as the first member.
  ///
  /// The creator's user profile is updated to reference the new family and
  /// is promoted to the parent role.
  ///
  /// :param name: Family name.
  /// :param description: Family description (optional).
  /// :param creatorId: ID of the user creating the family.
  /// :param photoUrl: Optional family photo URL.
  /// :returns: ``FamilyEntity`` on success or ``Failure`` on error.
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

      final creator = await _userRepository.getUserProfile(creatorId);
      if (creator == null) {
        return Left(NotFoundFailure('User profile not found'));
      }
      if (creator.familyId.value.isNotEmpty) {
        return Left(BusinessFailure('You already belong to a family'));
      }

      // Create family entity
      final now = DateTime.now();
      final family = FamilyEntity(
        id: FamilyId(const Uuid().v4()),
        name: name.trim(),
        description: description?.trim() ?? '',
        creatorId: creatorId,
        memberIds: [creatorId], // Creator is the first member
        createdAt: now,
        updatedAt: now,
        photoUrl: photoUrl,
        inviteCode: _generateInviteCode(),
      );

      await _familyRepository.createFamily(family);

      // Link the creator to the family as a parent.
      await _userRepository.updateUserProfile(
        creator.copyWith(
          familyId: family.id,
          role: UserRole.parent,
          updatedAt: DateTime.now(),
        ),
      );

      return Right(family);
    } catch (e) {
      return Left(ServerFailure('Failed to create family: $e'));
    }
  }

  String _generateInviteCode() {
    final random = Random.secure();
    return List.generate(
      6,
      (_) => _codeAlphabet[random.nextInt(_codeAlphabet.length)],
    ).join();
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
