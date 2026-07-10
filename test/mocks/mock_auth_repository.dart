import 'dart:async';
import 'package:hoque_family_chores/domain/repositories/auth_repository.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';

/// Minimal fake Firebase user for auth tests.
class FakeFirebaseUser {
  final String uid;
  final String? email;
  final String? displayName;

  FakeFirebaseUser({required this.uid, this.email, this.displayName});
}

/// Mock implementation of AuthRepository for testing.
///
/// [currentUser] defaults to null (signed out); set it to a
/// [FakeFirebaseUser] to simulate a persisted session.
class MockAuthRepository implements AuthRepository {
  FakeFirebaseUser? _currentUser;

  final _authStateController =
      StreamController<FakeFirebaseUser?>.broadcast();

  MockAuthRepository({FakeFirebaseUser? currentUser})
      : _currentUser = currentUser;

  @override
  dynamic get currentUser => _currentUser;

  @override
  Stream<dynamic> get authStateChanges => _authStateController.stream;

  @override
  Future<dynamic> signInWithApple() async {
    _currentUser =
        FakeFirebaseUser(uid: 'mock_apple_uid', email: 'apple@example.com');
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<dynamic> signInWithGoogle() async {
    _currentUser =
        FakeFirebaseUser(uid: 'mock_google_uid', email: 'google@example.com');
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<dynamic> signInWithEmailAndPassword(Email email, String password) async {
    _currentUser = FakeFirebaseUser(uid: 'mock_uid', email: email.value);
    return _currentUser;
  }

  @override
  Future<dynamic> createUserWithEmailAndPassword(Email email, String password) async {
    _currentUser = FakeFirebaseUser(uid: 'mock_uid', email: email.value);
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> deleteUser() async {
    _currentUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail(Email email) async {}

  @override
  Future<void> updateEmail(Email newEmail) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updateDisplayName(String newName) async {}

  @override
  Future<void> updatePhotoURL(String newPhotoURL) async {}

  @override
  Future<void> reauthenticate(Email email, String password) async {}

  @override
  Future<String?> getToken() async => 'mock_token';

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadUser() async {}
}
