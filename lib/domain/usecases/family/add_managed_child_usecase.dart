import 'package:dartz/dartz.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../../repositories/managed_child_repository.dart';
import '../../value_objects/family_id.dart';
import '../../value_objects/user_id.dart';

/// Adds a child with no phone of their own to a family.
///
/// The server (``addManagedChild``) is the real guard: it checks the caller is
/// a parent or guardian and enforces the 10-child cap. The checks here only
/// spare a round trip for an obviously bad name; they mirror the server's.
class AddManagedChildUseCase {
  AddManagedChildUseCase(this._repository);

  final ManagedChildRepository _repository;

  static const maxNameLength = 50;

  /// :param familyId: the family to add the child to.
  /// :param name: the child's name, as the family calls them.
  /// :returns: the new member's id, or a ``Failure`` with a message to show.
  Future<Either<Failure, UserId>> call({
    required FamilyId familyId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Left(ValidationFailure('Please enter a name.'));
    if (trimmed.length > maxNameLength) {
      return Left(ValidationFailure('That name is too long.'));
    }
    try {
      return Right(await _repository.addManagedChild(familyId, trimmed));
    } on DataException catch (e) {
      return Left(BusinessFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Could not add the child: $e'));
    }
  }
}
