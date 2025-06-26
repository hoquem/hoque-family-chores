import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/services/interfaces/auth_service_interface.dart';

/// Service for handling Firebase Authentication operations
class FirebaseAuthService implements AuthServiceInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _logger = AppLogger();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!;
    } catch (e) {
      _logger.e('Error signing in with email and password', error: e);
      rethrow;
    }
  }

  @override
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user!;
    } catch (e) {
      _logger.e('Error creating user with email and password', error: e);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.e('Error signing out', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deleteUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e) {
      _logger.e('Error deleting user', error: e);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.e('Error sending password reset email', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
    } catch (e) {
      _logger.e('Error updating email', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      _logger.e('Error updating password', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
    } catch (e) {
      _logger.e('Error updating display name', error: e);
      rethrow;
    }
  }

  @override
  Future<void> updatePhotoURL(String newPhotoURL) async {
    try {
      await _auth.currentUser?.updatePhotoURL(newPhotoURL);
    } catch (e) {
      _logger.e('Error updating photo URL', error: e);
      rethrow;
    }
  }

  @override
  Future<void> reauthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await _auth.currentUser?.reauthenticateWithCredential(credential);
    } catch (e) {
      _logger.e('Error reauthenticating user', error: e);
      rethrow;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      _logger.e('Error getting user token', error: e);
      return null;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      _logger.e('Error sending email verification', error: e);
      rethrow;
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      _logger.e('Error reloading user', error: e);
      rethrow;
    }
  }
}
