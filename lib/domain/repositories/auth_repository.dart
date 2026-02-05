import 'dart:async';
import '../value_objects/email.dart';

/// Abstract interface for authentication operations
abstract class AuthRepository {
  /// Get current user
  dynamic get currentUser;

  /// Sign in with email and password
  Future<dynamic> signInWithEmailAndPassword(Email email, String password);

  /// Create user with email and password
  Future<dynamic> createUserWithEmailAndPassword(Email email, String password);

  /// Sign out
  Future<void> signOut();

  /// Delete user
  Future<void> deleteUser();

  /// Send password reset email
  Future<void> sendPasswordResetEmail(Email email);

  /// Update email
  Future<void> updateEmail(Email newEmail);

  /// Update password
  Future<void> updatePassword(String newPassword);

  /// Update display name
  Future<void> updateDisplayName(String newName);

  /// Update photo URL
  Future<void> updatePhotoURL(String newPhotoURL);

  /// Reauthenticate user
  Future<void> reauthenticate(Email email, String password);

  /// Get user token
  Future<String?> getToken();

  /// Send email verification
  Future<void> sendEmailVerification();

  /// Reload user
  Future<void> reloadUser();
} 