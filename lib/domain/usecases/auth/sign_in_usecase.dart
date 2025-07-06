import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/email.dart';

/// Use case for user sign-in
class SignInUseCase {
  final AuthRepository _authRepository;

  SignInUseCase(this._authRepository);

  /// Signs in a user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// 
  /// Returns [dynamic] (user object) on success or [Failure] on error
  Future<Either<Failure, dynamic>> call({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input parameters
      final validationResult = _validateSignInInput(email: email, password: password);
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((failure) => failure, (_) => throw Exception('Unexpected')));
      }

      // Create Email value object
      final emailVO = Email(email.trim().toLowerCase());
      
      // Attempt sign-in
      final user = await _authRepository.signInWithEmailAndPassword(emailVO, password);
      return Right(user);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to sign in: $e'));
    }
  }

  /// Validates sign-in input parameters
  Either<Failure, void> _validateSignInInput({
    required String email,
    required String password,
  }) {
    // Validate email
    if (email.trim().isEmpty) {
      return Left(ValidationFailure('Email cannot be empty'));
    }

    // Validate password
    if (password.isEmpty) {
      return Left(ValidationFailure('Password cannot be empty'));
    }
    if (password.length < 6) {
      return Left(ValidationFailure('Password must be at least 6 characters'));
    }

    return const Right(null);
  }
} 