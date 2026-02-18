import 'dart:async';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of AuthRepository for testing
class MockAuthRepository implements AuthRepository {
  dynamic _currentUser;
  bool _isAuthenticated = false;

  @override
  dynamic get currentUser => _isAuthenticated ? _currentUser : null;

  @override
  Future<dynamic> signInWithEmailAndPassword(Email email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      // Simple mock validation
      if (email.value.isEmpty || password.isEmpty) {
        throw AuthException('Email and password cannot be empty', code: 'INVALID_CREDENTIALS');
      }
      
      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters', code: 'WEAK_PASSWORD');
      }
      
      // Mock successful authentication
      _currentUser = MockUser(
        uid: 'mock_user_${email.value.hashCode}',
        email: email.value,
        displayName: 'Mock User',
      );
      _isAuthenticated = true;
      
      return _currentUser;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to sign in: $e', code: 'SIGN_IN_ERROR');
    }
  }

  @override
  Future<dynamic> createUserWithEmailAndPassword(Email email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      // Simple mock validation
      if (email.value.isEmpty || password.isEmpty) {
        throw AuthException('Email and password cannot be empty', code: 'INVALID_CREDENTIALS');
      }
      
      if (password.length < 6) {
        throw AuthException('Password must be at least 6 characters', code: 'WEAK_PASSWORD');
      }
      
      // Mock successful user creation
      _currentUser = MockUser(
        uid: 'mock_user_${email.value.hashCode}',
        email: email.value,
        displayName: 'New User',
      );
      _isAuthenticated = true;
      
      return _currentUser;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to create user: $e', code: 'SIGN_UP_ERROR');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      throw AuthException('Failed to sign out: $e', code: 'SIGN_OUT_ERROR');
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      _currentUser = null;
      _isAuthenticated = false;
    } catch (e) {
      throw AuthException('Failed to delete user: $e', code: 'DELETE_USER_ERROR');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(Email email) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate network delay
      // Mock successful password reset email
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e', code: 'PASSWORD_RESET_ERROR');
    }
  }

  @override
  Future<void> updateEmail(Email newEmail) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      if (_currentUser != null) {
        _currentUser = MockUser(
          uid: _currentUser.uid,
          email: newEmail.value,
          displayName: _currentUser.displayName,
        );
      }
    } catch (e) {
      throw AuthException('Failed to update email: $e', code: 'UPDATE_EMAIL_ERROR');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      // Mock successful password update
    } catch (e) {
      throw AuthException('Failed to update password: $e', code: 'UPDATE_PASSWORD_ERROR');
    }
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      if (_currentUser != null) {
        _currentUser = MockUser(
          uid: _currentUser.uid,
          email: _currentUser.email,
          displayName: newName,
        );
      }
    } catch (e) {
      throw AuthException('Failed to update display name: $e', code: 'UPDATE_DISPLAY_NAME_ERROR');
    }
  }

  @override
  Future<void> updatePhotoURL(String newPhotoURL) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      // Mock successful photo URL update
    } catch (e) {
      throw AuthException('Failed to update photo URL: $e', code: 'UPDATE_PHOTO_URL_ERROR');
    }
  }

  @override
  Future<void> reauthenticate(Email email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400)); // Simulate network delay
      // Mock successful reauthentication
    } catch (e) {
      throw AuthException('Failed to reauthenticate: $e', code: 'REAUTHENTICATE_ERROR');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
      return _isAuthenticated ? 'mock_token_${_currentUser?.uid ?? 'unknown'}' : null;
    } catch (e) {
      throw AuthException('Failed to get token: $e', code: 'GET_TOKEN_ERROR');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      // Mock successful email verification
    } catch (e) {
      throw AuthException('Failed to send email verification: $e', code: 'EMAIL_VERIFICATION_ERROR');
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate network delay
      // Mock successful user reload
    } catch (e) {
      throw AuthException('Failed to reload user: $e', code: 'RELOAD_USER_ERROR');
    }
  }
}

/// Mock user class for testing
class MockUser {
  final String uid;
  final String email;
  final String displayName;

  MockUser({
    required this.uid,
    required this.email,
    required this.displayName,
  });
} 