import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  unknown,
  authenticating,
  error,
}

class AuthProvider with ChangeNotifier {
  final DataServiceInterface? _dataService;
  final FirebaseAuth _firebaseAuth;

  UserProfile? _currentUserProfile;
  String? _userFamilyId;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  // --- Public Getters ---
  UserProfile? get currentUserProfile => _currentUserProfile;
  String? get currentUserId => _currentUserProfile?.id;
  String? get userFamilyId => _userFamilyId;
  String? get displayName => _currentUserProfile?.name;
  String? get photoUrl => _currentUserProfile?.avatarUrl;
  String? get userEmail => _currentUserProfile?.email;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AuthProvider({FirebaseAuth? firebaseAuth, DataServiceInterface? dataService})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dataService = dataService {
    _initAuthStatus();
  }

  // updateDataService removed from previous review, as it's passed in constructor now.

  Future<void> _initAuthStatus() async {
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          logger.i("AuthProvider: Firebase user is null (signed out or no session).");
          _currentUserProfile = null;
          _userFamilyId = null;
          _setStatus(AuthStatus.unauthenticated);
        } else {
          logger.i("AuthProvider: Firebase user found: ${firebaseUser.uid}. Fetching profile.");
          if (_dataService != null) {
            _currentUserProfile = await _dataService!.getUserProfile(userId: firebaseUser.uid);
            _userFamilyId = _currentUserProfile?.familyId;

            if (_currentUserProfile != null) {
              _setStatus(AuthStatus.authenticated);
              logger.i("AuthProvider: User profile loaded for ${firebaseUser.uid}. Status: authenticated.");
            } else {
              logger.w("AuthProvider: Firebase user ${firebaseUser.uid} authenticated, but no UserProfile found in Firestore.");
              _setStatus(AuthStatus.unauthenticated);
            }
          } else {
            logger.w("AuthProvider: DataService is null, cannot fetch user profile for ${firebaseUser.uid}.");
            _setStatus(AuthStatus.error);
          }
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, s) {
      logger.e("AuthProvider: Failed to initialize auth status: $e", error: e, stackTrace: s);
      _errorMessage = "Failed to initialize authentication: $e";
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.error);
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Public Methods (removed @override for direct methods not overriding ChangeNotifier) ---
  Future<void> signIn({required String email, required String password}) async { // <--- REMOVED @override
    logger.i("Attempting sign-in for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      logger.i("Sign-in successful for ${userCredential.user?.uid}.");
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      logger.e("Sign-in failed for $email: ${e.code}", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during sign-in: $e";
      logger.e("Sign-in failed for $email: $e", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async { // <--- REMOVED @override
    logger.i("Attempting sign-out.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.signOut();
      logger.i("Sign-out successful.");
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An error occurred during sign out.";
      logger.e("Sign-out failed: ${e.code}", error: e, stackTrace: s);
      _setStatus(AuthStatus.error);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during sign out: $e";
      logger.e("Sign-out failed: $e", error: e, stackTrace: s);
      _setStatus(AuthStatus.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({required String email}) async { // <--- REMOVED @override
    logger.i("Attempting password reset for $email.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      logger.i("Password reset email sent to $email.");
      _errorMessage = "Password reset email sent. Check your inbox.";
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "Password reset failed.";
      logger.e("Password reset failed for $email: ${e.code}", error: e, stackTrace: s);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during password reset: $e";
      logger.e("Password reset failed for $email: $e", error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async { // <--- REMOVED @override
    if (_firebaseAuth.currentUser?.uid == null || _dataService == null) {
      logger.w("Cannot refresh user profile: user not logged in or DataService not available.");
      return;
    }
    logger.i("Refreshing user profile for ${_firebaseAuth.currentUser!.uid}.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _dataService!.getUserProfile(userId: _firebaseAuth.currentUser!.uid);
      if (updatedProfile != null) {
        _currentUserProfile = updatedProfile;
        _userFamilyId = updatedProfile.familyId;
        logger.d("User profile refreshed successfully.");
      } else {
        logger.w("Refreshed user profile not found for ID: ${_firebaseAuth.currentUser!.uid}.");
      }
    } catch (e, s) {
      logger.e("Error refreshing user profile: $e", error: e, stackTrace: s);
      _errorMessage = "Failed to refresh profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserProfile? getFamilyMember(String userId) { // <--- REMOVED @override
    if (_dataService != null) {
      final userData = MockData.userProfiles.firstWhere(
        (profile) => profile['id'] == userId,
        orElse: () => {},
      );

      if (userData.isNotEmpty) {
        return UserProfile.fromMap(userData);
      }
    }
    return null;
  }

  void _setStatus(AuthStatus newStatus) {
    _status = newStatus;
  }
}