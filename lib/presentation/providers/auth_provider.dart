import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  final GamificationServiceInterface? _gamificationService;
  final UserProfileServiceInterface? _userProfileService;
  final FirebaseAuth _firebaseAuth;
  final _logger = AppLogger();

  UserProfile? _currentUserProfile;
  String? _userFamilyId;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  UserProfile? get currentUserProfile => _currentUserProfile;
  String? get currentUserId => _currentUserProfile?.member.id;
  String? get userFamilyId => _userFamilyId;
  String? get displayName => _currentUserProfile?.member.name;
  String? get photoUrl => _currentUserProfile?.member.photoUrl;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  UserProfile? get currentUser => _currentUserProfile;

  AuthProvider({
    FirebaseAuth? firebaseAuth,
    GamificationServiceInterface? gamificationService,
    UserProfileServiceInterface? userProfileService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _gamificationService = gamificationService,
       _userProfileService = userProfileService {
    _initAuthStatus();
  }

  Future<void> _initAuthStatus() async {
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          _logger.i(
            "AuthProvider: Firebase user is null (signed out or no session).",
          );
          _currentUserProfile = null;
          _userFamilyId = null;
          _setStatus(AuthStatus.unauthenticated);
        } else {
          _logger.i(
            "AuthProvider: Firebase user found: ${firebaseUser.uid}. Fetching profile.",
          );
          await _fetchAndSetUserProfile(firebaseUser.uid);
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, s) {
      _logger.e(
        "AuthProvider: Failed to initialize auth status: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = "Failed to initialize authentication: $e";
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.error);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchAndSetUserProfile(String userId) async {
    if (_userProfileService == null) {
      _logger.w(
        "AuthProvider: UserProfileService is null, cannot fetch user profile for $userId.",
      );
      _setStatus(AuthStatus.error);
      return;
    }

    try {
      _currentUserProfile = await _userProfileService.getUserProfile(
        userId: userId,
      );
      if (_currentUserProfile != null) {
        _userFamilyId = _currentUserProfile?.member.familyId;
        _setStatus(AuthStatus.authenticated);
        _logger.i(
          "AuthProvider: User profile loaded for $userId. Status: authenticated.",
        );
      } else {
        _logger.w(
          "AuthProvider: Firebase user $userId authenticated, but no UserProfile found in Firestore. Setting status to unauthenticated (needs family setup).",
        );
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e, s) {
      _logger.e(
        "AuthProvider: Error fetching/creating user profile for $userId: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = "Failed to load user profile: $e";
      _setStatus(AuthStatus.error);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    _logger.i("Attempting sign-in for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      _logger.i("Sign-in successful for ${userCredential.user?.uid}.");

      await _fetchAndSetUserProfile(userCredential.user!.uid);

      if (_currentUserProfile != null &&
          _userFamilyId != null &&
          _gamificationService != null) {
        await _gamificationService.initializeUserData(
          userId: _currentUserProfile!.member.id,
          familyId: _userFamilyId!,
        );
      }
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      _logger.e(
        "Sign-in failed for $email: ${e.code}",
        error: e,
        stackTrace: s,
      );
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during sign-in: $e";
      _logger.e("Sign-in failed for $email: $e", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _logger.i("Attempting sign-up for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      _logger.i("Sign-up successful for ${userCredential.user?.uid}.");

      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        _logger.i(
          "Updated display name for user ${userCredential.user?.uid} to: $displayName",
        );
      }
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown registration error occurred.";
      _logger.e(
        "Sign-up failed for $email: ${e.code}",
        error: e,
        stackTrace: s,
      );
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during registration: $e";
      _logger.e("Sign-up failed for $email: $e", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _logger.i("Attempting sign-out.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.signOut();
      _logger.i("Sign-out successful.");
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "Failed to sign out: $e";
      _logger.e("Sign-out failed: $e", error: e, stackTrace: s);
      _setStatus(AuthStatus.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }
}
