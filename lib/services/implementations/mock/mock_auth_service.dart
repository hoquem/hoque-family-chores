import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/services/interfaces/auth_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';

/// Mock implementation of [AuthServiceInterface] for testing
class MockAuthService implements AuthServiceInterface {
  MockAuthService();

  User? _currentUser;

  @override
  User? get currentUser => _currentUser;

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // Simulate successful sign in
        return MockUser();
      },
      operationName: 'signInWithEmailAndPassword',
      context: {'email': email},
    );
  }

  @override
  Future<User> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // Simulate successful user creation
        return MockUser();
      },
      operationName: 'createUserWithEmailAndPassword',
      context: {'email': email},
    );
  }

  @override
  Future<void> signOut() async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _currentUser = null;
      },
      operationName: 'signOut',
    );
  }

  @override
  Future<void> deleteUser() async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _currentUser = null;
      },
      operationName: 'deleteUser',
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'sendPasswordResetEmail',
      context: {'email': email},
    );
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'updateEmail',
      context: {'email': newEmail},
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'updatePassword',
    );
  }

  @override
  Future<void> updateDisplayName(String newName) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'updateDisplayName',
      context: {'displayName': newName},
    );
  }

  @override
  Future<void> updatePhotoURL(String newPhotoURL) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'updatePhotoURL',
      context: {'photoURL': newPhotoURL},
    );
  }

  @override
  Future<void> reauthenticate(String email, String password) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'reauthenticate',
      context: {'email': email},
    );
  }

  @override
  Future<String?> getToken() async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        return 'mock_token';
      },
      operationName: 'getToken',
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'sendEmailVerification',
    );
  }

  @override
  Future<void> reloadUser() async {
    return ServiceUtils.handleServiceCall(
      operation: () async {},
      operationName: 'reloadUser',
    );
  }
}

/// Mock implementation of [User] for testing
class MockUser implements User {
  @override
  bool get emailVerified => true;

  @override
  String? get email => 'test@example.com';

  @override
  String? get displayName => 'Test User';

  @override
  String? get photoURL => 'https://example.com/avatar.jpg';

  @override
  String get uid => 'test_user_id';

  @override
  bool get isAnonymous => false;

  @override
  List<UserInfo> get providerData => [];

  @override
  String? get phoneNumber => null;

  @override
  UserMetadata get metadata => MockUserMetadata();

  @override
  List<String> get providerId => [];

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  String? get refreshToken => 'mock_refresh_token';

  @override
  String? get tenantId => null;

  @override
  Future<void> delete() async {}

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_token';

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {}

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithProvider(
    AuthProvider provider,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updateEmail(String? email) async {}

  @override
  Future<void> updatePassword(String? password) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<User> unlink(String providerId) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithRedirect(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithRedirect(
    AuthProvider provider,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {}
}

/// Mock implementation of [UserMetadata] for testing
class MockUserMetadata implements UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now();

  @override
  DateTime? get lastSignInTime => DateTime.now();
}
