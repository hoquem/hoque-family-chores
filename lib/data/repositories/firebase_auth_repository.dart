import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  dynamic get currentUser => _auth.currentUser;

  @override
  Future<dynamic> signInWithEmailAndPassword(Email email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.value,
        password: password,
      );
      return userCredential.user!;
    } catch (e) {
      throw AuthException('Failed to sign in: $e', code: 'SIGN_IN_ERROR');
    }
  }

  @override
  Future<dynamic> createUserWithEmailAndPassword(Email email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.value,
        password: password,
      );
      return userCredential.user!;
    } catch (e) {
      throw AuthException('Failed to create user: $e', code: 'SIGN_UP_ERROR');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Failed to sign out: $e', code: 'SIGN_OUT_ERROR');
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      throw AuthException('Failed to delete user: $e', code: 'DELETE_USER_ERROR');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(Email email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.value);
    } catch (e) {
      throw AuthException('Failed to send password reset email: $e', code: 'PASSWORD_RESET_ERROR');
    }
  }

  @override
  Future<void> updateEmail(Email newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail.value);
    } catch (e) {
      throw AuthException('Failed to update email: $e', code: 'UPDATE_EMAIL_ERROR');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      throw AuthException('Failed to update password: $e', code: 'UPDATE_PASSWORD_ERROR');
    }
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      throw AuthException('Failed to update display name: $e', code: 'UPDATE_DISPLAY_NAME_ERROR');
    }
  }

  @override
  Future<void> updatePhotoURL(String newPhotoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(newPhotoURL);
    } catch (e) {
      throw AuthException('Failed to update photo URL: $e', code: 'UPDATE_PHOTO_URL_ERROR');
    }
  }

  @override
  Future<void> reauthenticate(Email email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email.value,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      throw AuthException('Failed to reauthenticate: $e', code: 'REAUTHENTICATE_ERROR');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      throw AuthException('Failed to get token: $e', code: 'GET_TOKEN_ERROR');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw AuthException('Failed to send email verification: $e', code: 'EMAIL_VERIFICATION_ERROR');
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      throw AuthException('Failed to reload user: $e', code: 'RELOAD_USER_ERROR');
    }
  }
} 