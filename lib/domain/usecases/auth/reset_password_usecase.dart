import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/email.dart';

/// Use case for sending a password reset email
class ResetPasswordUseCase {
  final AuthRepository _authRepository;

  ResetPasswordUseCase(this._authRepository);

  /// Sends a password reset email
  ///
  /// [email] - User's email address
  ///
  /// Returns [void] on success or [Failure] on error
  Future<Either<Failure, void>> call(Email email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
} 