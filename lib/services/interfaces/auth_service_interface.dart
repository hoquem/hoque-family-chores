import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthServiceInterface {
  User? get currentUser;

  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> deleteUser();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateEmail(String newEmail);
  Future<void> updatePassword(String newPassword);
  Future<void> updateDisplayName(String newName);
  Future<void> updatePhotoURL(String newPhotoURL);
  Future<void> reauthenticate(String email, String password);
  Future<String?> getToken();
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
}
