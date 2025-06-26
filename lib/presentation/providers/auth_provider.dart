import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:uuid/uuid.dart';

class AuthProvider with ChangeNotifier {
  final GamificationServiceInterface? _gamificationService;
  final UserProfileServiceInterface? _userProfileService;
  final FirebaseAuth _firebaseAuth;

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
  
  String? get userEmail => _firebaseAuth.currentUser?.email;

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
      logger.i("[AuthProvider] Listening to Firebase auth state changes...");
      _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
        logger.i("[AuthProvider] Firebase auth state changed. User: $firebaseUser");
        if (firebaseUser == null) {
          logger.i("[AuthProvider] Firebase user is null (signed out or no session). Setting status to unauthenticated.");
          _currentUserProfile = null;
          _userFamilyId = null;
          _setStatus(AuthStatus.unauthenticated);
        } else {
          logger.i("[AuthProvider] Firebase user found: ${firebaseUser.uid}. Fetching profile.");
          await _fetchAndSetUserProfile(firebaseUser.uid);
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, s) {
      logger.e("[AuthProvider] Failed to initialize auth status: $e", error: e, stackTrace: s);
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
      logger.w("[AuthProvider] UserProfileService is null, cannot fetch user profile for $userId.");
      _setStatus(AuthStatus.error);
      return;
    }

    try {
      logger.i("[AuthProvider] Fetching user profile for $userId...");
      _currentUserProfile = await _userProfileService.getUserProfile(userId: userId);
      if (_currentUserProfile != null) {
        _userFamilyId = _currentUserProfile?.member.familyId;
        logger.i("[AuthProvider] User profile loaded for $userId. Status: authenticated. FamilyId: $_userFamilyId");
        _setStatus(AuthStatus.authenticated);
      } else {
        logger.w("[AuthProvider] Firebase user $userId authenticated, but no UserProfile found in Firestore. Setting status to unauthenticated (needs family setup).",);
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e, s) {
      logger.e("[AuthProvider] Error fetching/creating user profile for $userId: $e", error: e, stackTrace: s);
      _errorMessage = "Failed to load user profile: $e";
      _setStatus(AuthStatus.error);
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    logger.i("[AuthProvider] Attempting sign-in for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      logger.i("[AuthProvider] Sign-in successful for ${userCredential.user?.uid}.");

      await _fetchAndSetUserProfile(userCredential.user!.uid);

      if (_currentUserProfile != null && _userFamilyId != null && _gamificationService != null) {
        logger.i("[AuthProvider] Initializing gamification data for user ${_currentUserProfile!.member.id} and family $_userFamilyId");
        await _gamificationService.initializeUserData(
          userId: _currentUserProfile!.member.id,
          familyId: _userFamilyId!,
        );
      } else {
        logger.w("[AuthProvider] GamificationService or user/family ID missing after sign-in.");
      }
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown authentication error occurred.";
      logger.e("[AuthProvider] Sign-in failed for $email: ${e.code}", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during sign-in: $e";
      logger.e("[AuthProvider] Sign-in failed for $email: $e", error: e, stackTrace: s);
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
    logger.i("[AuthProvider] Attempting sign-up for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      logger.i("[AuthProvider] Sign-up successful for ${userCredential.user?.uid}.");

      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        logger.i("[AuthProvider] Updated display name for user ${userCredential.user?.uid} to: $displayName");
      }
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown registration error occurred.";
      logger.e("[AuthProvider] Sign-up failed for $email: ${e.code}", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during registration: $e";
      logger.e("[AuthProvider] Sign-up failed for $email: $e", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    logger.i("[AuthProvider] Attempting sign-out.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.signOut();
      logger.i("[AuthProvider] Sign-out successful.");
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "Failed to sign out: $e";
      logger.e("[AuthProvider] Sign-out failed: $e", error: e, stackTrace: s);
      _setStatus(AuthStatus.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword({required String email}) async {
    logger.i("[AuthProvider] Attempting password reset for $email.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      logger.i("[AuthProvider] Password reset email sent successfully to $email.");
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown password reset error occurred.";
      logger.e("[AuthProvider] Password reset failed for $email: ${e.code}", error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during password reset: $e";
      logger.e("[AuthProvider] Password reset failed for $email: $e", error: e, stackTrace: s);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async {
    logger.i("[AuthProvider] Refreshing user profile.");
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      await _fetchAndSetUserProfile(currentUser.uid);
    } else {
      logger.w("[AuthProvider] Cannot refresh user profile: no current user.");
    }
  }

  Future<void> createFamilyAndSetProfile({
    required String familyName,
    required String familyDescription,
    required String creatorEmail,
  }) async {
    logger.i("[AuthProvider] Creating family and setting up user profile.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) {
        logger.e("[AuthProvider] No authenticated user found when creating family.");
        throw Exception('No authenticated user found');
      }

      final now = DateTime.now();
      final familyMember = FamilyMember(
        id: currentUser.uid,
        userId: currentUser.uid,
        familyId: const Uuid().v4(),
        name: currentUser.displayName ?? 'New User',
        photoUrl: currentUser.photoURL,
        role: FamilyRole.parent,
        points: 0,
        joinedAt: now,
        updatedAt: now,
      );

      final userProfile = UserProfile(
        id: currentUser.uid,
        member: familyMember,
        points: 0,
        badges: [],
        achievements: [],
        createdAt: now,
        updatedAt: now,
        completedTasks: [],
        inProgressTasks: [],
        availableTasks: [],
        preferences: {},
        statistics: {},
      );

      if (_userProfileService != null) {
        logger.i("[AuthProvider] Creating user profile in service...");
        await _userProfileService.createUserProfile(userProfile: userProfile);
      } else {
        logger.e("[AuthProvider] UserProfileService is null during family creation.");
      }

      if (_gamificationService != null) {
        logger.i("[AuthProvider] Initializing gamification data for new family...");
        await _gamificationService.initializeUserData(
          userId: currentUser.uid,
          familyId: familyMember.familyId,
        );
      } else {
        logger.e("[AuthProvider] GamificationService is null during family creation.");
      }

      _currentUserProfile = userProfile;
      _userFamilyId = familyMember.familyId;
      _setStatus(AuthStatus.authenticated);

      logger.i("[AuthProvider] Family and user profile created successfully.");
    } catch (e, s) {
      _errorMessage = "Failed to create family and profile: $e";
      logger.e("[AuthProvider] Error creating family and profile: $e", error: e, stackTrace: s);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus newStatus) {
    logger.i("[AuthProvider] Status changing from $_status to $newStatus");
    _status = newStatus;
    logger.d("[AuthProvider] Calling notifyListeners()");
    notifyListeners();
    logger.d("[AuthProvider] notifyListeners() completed");
  }
}
