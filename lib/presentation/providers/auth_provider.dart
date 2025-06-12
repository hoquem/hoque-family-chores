import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/enums.dart'; // Needed for AuthStatus, FamilyRole
import 'package:hoque_family_chores/models/family.dart'; // Needed for Family model
import 'package:hoque_family_chores/services/data_service_interface.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart'; // For constants like family ID
import 'package:uuid/uuid.dart'; // <--- NEW: Import uuid

class AuthProvider with ChangeNotifier {
  final DataServiceInterface? _dataService;
  final FirebaseAuth _firebaseAuth;

  UserProfile? _currentUserProfile;
  String? _userFamilyId;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _isLoading = false;

  // ... (existing getters and constructor)
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

  Future<void> _initAuthStatus() async {
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _firebaseAuth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser == null) {
          logger.i(
            "AuthProvider: Firebase user is null (signed out or no session).",
          );
          _currentUserProfile = null;
          _userFamilyId = null;
          _setStatus(AuthStatus.unauthenticated);
        } else {
          logger.i(
            "AuthProvider: Firebase user found: ${firebaseUser.uid}. Fetching profile.",
          );
          await _fetchAndSetUserProfile(firebaseUser.uid, firebaseUser.email);
        }
        _isLoading = false;
        notifyListeners();
      });
    } catch (e, s) {
      logger.e(
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

  // --- Helper to fetch and set user profile after auth state change or sign-in ---
  Future<void> _fetchAndSetUserProfile(String userId, String? email) async {
    if (_dataService == null) {
      logger.w(
        "AuthProvider: DataService is null, cannot fetch user profile for $userId.",
      );
      _setStatus(AuthStatus.error);
      return;
    }

    try {
      _currentUserProfile = await _dataService.getUserProfile(userId: userId);
      if (_currentUserProfile != null) {
        _userFamilyId = _currentUserProfile?.familyId;
        _setStatus(AuthStatus.authenticated);
        logger.i(
          "AuthProvider: User profile loaded for $userId. Status: authenticated.",
        );
      } else {
        // User authenticated in Firebase Auth, but no profile in Firestore.
        // This is a new user or profile creation failed previously.
        logger.w(
          "AuthProvider: Firebase user $userId authenticated, but no UserProfile found in Firestore. Setting status to unauthenticated (needs family setup).",
        );
        // No longer auto-create a default profile here. AuthWrapper will direct to FamilySetupScreen.
        _setStatus(
          AuthStatus.unauthenticated,
        ); // Indicate that auth succeeded, but app data is missing.
      }
    } catch (e, s) {
      logger.e(
        "AuthProvider: Error fetching/creating user profile for $userId: $e",
        error: e,
        stackTrace: s,
      );
      _errorMessage = "Failed to load user profile: $e";
      _setStatus(AuthStatus.error);
    }
  }

  // --- Public Methods (signIn, signUp, signOut, etc.) ---
  Future<void> signIn({required String email, required String password}) async {
    logger.i("Attempting sign-in for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      logger.i("Sign-in successful for ${userCredential.user?.uid}.");
      // After sign-in, ensure user profile exists or is created
      await _fetchAndSetUserProfile(
        userCredential.user!.uid,
        userCredential.user!.email,
      ); // Fetch/create profile for the signed-in user
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

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    logger.i("Attempting sign-up for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      logger.i("Sign-up successful for ${userCredential.user?.uid}.");

      // Update the user's display name in Firebase Auth
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user?.updateDisplayName(displayName);
        logger.i(
          "Updated display name for user ${userCredential.user?.uid} to: $displayName",
        );
      }

      // For sign-up, *do not* directly create a default profile here anymore.
      // The AuthWrapper will observe the new user (AuthStatus.authenticated but userFamilyId=null)
      // and redirect to FamilySetupScreen, where _createFamilyAndSetProfile will be called.
      // This ensures the user *explicitly* creates their family.
      // _currentUserProfile and _userFamilyId will be set once _createFamilyAndSetProfile is successful.
    } on FirebaseAuthException catch (e, s) {
      _errorMessage = e.message ?? "An unknown registration error occurred.";
      logger.e("Sign-up failed for $email: ${e.code}", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during sign-up: $e";
      logger.e("Sign-up failed for $email: $e", error: e, stackTrace: s);
      _currentUserProfile = null;
      _userFamilyId = null;
      _setStatus(AuthStatus.unauthenticated);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
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

  Future<void> resetPassword({required String email}) async {
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
      logger.e(
        "Password reset failed for $email: ${e.code}",
        error: e,
        stackTrace: s,
      );
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during password reset: $e";
      logger.e("Password reset failed for $email: $e", error: e, stackTrace: s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async {
    if (_firebaseAuth.currentUser?.uid == null || _dataService == null) {
      logger.w(
        "Cannot refresh user profile: user not logged in or DataService not available.",
      );
      return;
    }
    logger.i("Refreshing user profile for ${_firebaseAuth.currentUser!.uid}.");
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedProfile = await _dataService.getUserProfile(
        userId: _firebaseAuth.currentUser!.uid,
      );
      if (updatedProfile != null) {
        _currentUserProfile = updatedProfile;
        _userFamilyId = updatedProfile.familyId;
        logger.d("User profile refreshed successfully.");
      } else {
        logger.w(
          "Refreshed user profile not found for ID: ${_firebaseAuth.currentUser!.uid}.",
        );
      }
    } catch (e, s) {
      logger.e("Error refreshing user profile: $e", error: e, stackTrace: s);
      _errorMessage = "Failed to refresh profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  UserProfile? getFamilyMember(String userId) {
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

  // --- NEW: Public method to create family and set user profile ---
  Future<void> createFamilyAndSetProfile({
    required String familyName,
    required String creatorUserId,
    String? creatorEmail,
    String? creatorName,
  }) async {
    logger.i(
      "AuthProvider: Attempting to create family and set user profile for $creatorUserId.",
    );
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_dataService == null) {
      _errorMessage = "DataService not available for family creation.";
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Get the current Firebase user to access their display name
      final currentUser = _firebaseAuth.currentUser;
      final displayName = currentUser?.displayName;

      // 1. Generate a unique Family ID
      String uniqueFamilyId = const Uuid().v4();
      logger.d("Generated unique family ID: $uniqueFamilyId");

      // 2. Create the Family object
      Family newFamily = Family(
        id: uniqueFamilyId,
        name: familyName,
        creatorUserId: creatorUserId,
        createdAt: DateTime.now(),
        memberUserIds: [creatorUserId], // Creator is the first member
      );

      // 3. Create the Family document in Firestore
      await _dataService.createFamily(family: newFamily);
      logger.i(
        "Family '$familyName' created successfully with ID: $uniqueFamilyId",
      );

      // 4. Create/Update the UserProfile with family details and role
      String userName =
          displayName ??
          creatorName ??
          (creatorEmail?.split('@').first ?? 'New User');

      UserProfile userProfileToCreate = UserProfile(
        id: creatorUserId,
        name: userName,
        email: creatorEmail,
        role: FamilyRole.parent, // Creator is parent by default
        familyId: uniqueFamilyId,
        joinedAt: DateTime.now(),
        // Default gamification fields
        totalPoints: 0,
        currentLevel: 0,
        completedTasks: 0,
        currentStreak: 0,
        longestStreak: 0,
        unlockedBadges: [],
        redeemedRewards: [],
        achievements: [],
        lastTaskCompletedAt: null,
      );

      // If a profile already exists (e.g., from _initAuthStatus seeing Firebase user but no profile), update it.
      // Otherwise, create it.
      UserProfile? existingProfile = await _dataService.getUserProfile(
        userId: creatorUserId,
      );
      if (existingProfile != null) {
        await _dataService.updateUserProfile(
          user: existingProfile.copyWith(
            role: FamilyRole.parent,
            familyId: uniqueFamilyId,
            name: userName,
            email: creatorEmail,
          ),
        );
        _currentUserProfile = existingProfile.copyWith(
          role: FamilyRole.parent,
          familyId: uniqueFamilyId,
          name: userName,
          email: creatorEmail,
        );
      } else {
        await _dataService.createUserProfile(userProfile: userProfileToCreate);
        _currentUserProfile = userProfileToCreate;
      }

      // 5. Update AuthProvider's internal state
      _userFamilyId = uniqueFamilyId;
      _setStatus(AuthStatus.authenticated);
      logger.i(
        "User profile for $creatorUserId updated with family ID: $uniqueFamilyId. Status: authenticated.",
      );
    } on FirebaseException catch (e, s) {
      _errorMessage =
          e.message ?? "Firebase error during family creation: ${e.code}";
      logger.e(
        "Firebase error creating family for $creatorUserId: $e",
        error: e,
        stackTrace: s,
      );
      _setStatus(AuthStatus.error);
    } catch (e, s) {
      _errorMessage = "An unexpected error occurred during family creation: $e";
      logger.e(
        "Unexpected error creating family for $creatorUserId: $e",
        error: e,
        stackTrace: s,
      );
      _setStatus(AuthStatus.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus newStatus) {
    _status = newStatus;
  }
}
