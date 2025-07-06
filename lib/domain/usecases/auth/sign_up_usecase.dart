import 'package:dartz/dartz.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/auth_repository.dart';
import '../../value_objects/email.dart';

/// Use case for user registration
class SignUpUseCase {
  final AuthRepository _authRepository;

  SignUpUseCase(this._authRepository);

  /// Registers a new user with email and password
  /// 
  /// [email] - User's email address
  /// [password] - User's password
  /// [displayName] - User's display name (optional)
  /// 
  /// Returns [dynamic] (user object) on success or [Failure] on error
  Future<Either<Failure, dynamic>> call({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Validate input parameters
      final validationResult = _validateSignUpInput(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (validationResult.isLeft()) {
        return Left(validationResult.fold((failure) => failure, (_) => throw Exception('Unexpected')));
      }

      // Create Email value object
      final emailVO = Email(email.trim().toLowerCase());
      
      // Attempt registration
      final user = await _authRepository.createUserWithEmailAndPassword(emailVO, password);
      
      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty) {
        await _authRepository.updateDisplayName(displayName.trim());
      }
      
      return Right(user);
    } on DataException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure('Failed to register user: $e'));
    }
  }

  /// Validates sign-up input parameters
  Either<Failure, void> _validateSignUpInput({
    required String email,
    required String password,
    String? displayName,
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
    if (password.length > 128) {
      return Left(ValidationFailure('Password cannot exceed 128 characters'));
    }

    // Validate display name
    if (displayName != null && displayName.trim().isNotEmpty) {
      if (displayName.trim().length < 2) {
        return Left(ValidationFailure('Display name must be at least 2 characters'));
      }
      if (displayName.trim().length > 50) {
        return Left(ValidationFailure('Display name cannot exceed 50 characters'));
      }
    }

    return const Right(null);
  }
} 