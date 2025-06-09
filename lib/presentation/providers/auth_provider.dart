// lib/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/utils/exceptions.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/services/data_service_interface.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  DataServiceInterface? _dataService;
  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // --- Public Getters for UI ---
  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get currentUserProfile => _userProfile;
  String? get currentUserId => _userProfile?.id;
  String? get userFamilyId => _userProfile?.familyId;
  String? get displayName => _userProfile?.name;
  String? get userEmail => _userProfile?.email;
  String? get photoUrl => _userProfile?.avatarUrl;

  /// Injected by ProxyProvider in main.dart
  void updateDataService(DataServiceInterface dataService) {
    if (_dataService == null) {
      _dataService = dataService;
      checkInitialAuthStatus();
    }
  }

  /// Checks for an existing session when the app starts.
  Future<void> checkInitialAuthStatus() async {
    if (_dataService == null) return;
    
    final bool authenticated = await _dataService!.isAuthenticated();
    if (authenticated) {
      final userId = _dataService!.getCurrentUserId();
      if (userId != null) {
        // After authenticating, we must also load the profile data.
        await _loadUserProfile(userId);
      } else {
        _updateStatus(AuthStatus.unauthenticated);
      }
    } else {
      _updateStatus(AuthStatus.unauthenticated);
    }
  }

  /// Handles the entire sign-in flow.
  /// Returns `true` only if both authentication AND profile loading succeed.
Future<bool> signIn({required String email, required String password}) async {
    if (_dataService == null) return false;
    _startLoading();
    
    // MODIFIED: Catch block now includes the stack trace `s`
    try {
      final userId = await _dataService!.signIn(email: email, password: password);
      
      if (userId != null) {
        await _loadUserProfile(userId);
        
        if (_status == AuthStatus.authenticated) {
          _stopLoading();
          return true;
        }
      }
      // If we get here, something failed. Throw our custom exception.
      throw AuthException('Sign in failed. Please check your credentials.');

    } catch (e, s) { // MODIFIED: Catch the error AND the stack trace
      // ADDED: Log the full error and stack trace to the console
      logger.e('Sign In Failed', error: e, stackTrace: s);
      
      // Pass a user-friendly message to the UI
      _stopLoading(error: e is AppException ? e.message : 'An unexpected error occurred.');
      return false;
    }
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    if (_dataService == null) return;
    await _dataService!.signOut();
    _userProfile = null;
    _updateStatus(AuthStatus.unauthenticated);
  }

  /// Refreshes the current user's profile data.
  Future<void> refreshUserProfile() async {
    if (currentUserId != null) {
      await _loadUserProfile(currentUserId!);
    }
  }

  /// Private helper to load profile data and update the state.
  /// Throws an exception if the profile cannot be found.
  Future<void> _loadUserProfile(String userId) async {
    try {
      final profileMap = await _dataService!.getUserProfile(userId: userId);
      if (profileMap != null) {
        _userProfile = UserProfile.fromMap(profileMap);
        _updateStatus(AuthStatus.authenticated);
      } else {
        await _dataService!.signOut();
        // MODIFIED: Throw our custom exception for clarity
        throw AuthException('Your user profile could not be found in the database.');
      }
    } catch (e) {
      _userProfile = null;
      _updateStatus(AuthStatus.unauthenticated);
      // Re-throw the error so the calling method (signIn) can catch it
      rethrow;
    }
  }

  // --- Private state management helpers ---
  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading({String? error}) {
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }
  
  void _updateStatus(AuthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  // You should add the signUp and resetPassword methods here as well...
  Future<bool> signUp({ required String email, required String password, required String displayName, }) async { return false; }
  Future<void> resetPassword({required String email}) async {}
}