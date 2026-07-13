import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Hide the package's own nonce helper: this app uses the unit-tested one from
// data/auth/apple_nonce.dart.
import 'package:sign_in_with_apple/sign_in_with_apple.dart' hide generateNonce;
import '../../domain/repositories/auth_repository.dart';
import '../../domain/value_objects/email.dart';
import '../../core/error/exceptions.dart';
import '../auth/apple_nonce.dart';
import '../auth/oauth_error_mapper.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance;

  @override
  dynamic get currentUser => _auth.currentUser;

  @override
  Stream<dynamic> get authStateChanges => _auth.authStateChanges();

  @override
  List<String> get currentProviderIds =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  @override
  Future<dynamic> signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256OfString(rawNonce),
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final cred = await _auth.signInWithCredential(oauthCredential);
      return cred.user!;
    } on SignInWithAppleAuthorizationException catch (e) {
      throw mapAppleAuthorizationError(e);
    } on FirebaseAuthException catch (e) {
      throw mapOAuthError(e);
    }
  }

  @override
  Future<dynamic> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw const AuthException(
          'Google sign-in cancelled',
          code: 'SIGN_IN_CANCELLED',
        );
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await _auth.signInWithCredential(credential);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw mapOAuthError(e);
    }
  }

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
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('No signed-in user to delete',
          code: 'NO_CURRENT_USER');
    }
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Account deletion requires a recent sign-in',
          code: 'REQUIRES_RECENT_LOGIN',
        );
      }
      throw AuthException('Failed to delete user: ${e.message}',
          code: 'DELETE_USER_ERROR');
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