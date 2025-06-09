// lib/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
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

  // This is the main object for UI to get user data
  UserProfile? get currentUser => _userProfile;

  // Convenience getters that UI screens were asking for
  String? get currentUserId => _userProfile?.id;
  String? get userFamilyId => _userProfile?.familyId;
  String? get displayName => _userProfile?.name;
  String? get userEmail => _userProfile?.email;
  String? get photoUrl => _userProfile?.avatarUrl;

  // Method for ProxyProvider to inject the service
  void updateDataService(DataServiceInterface dataService) {
    _dataService = dataService;
    checkInitialAuthStatus();
  }

  Future<void> checkInitialAuthStatus() async {
    if (_dataService == null) return;
    
    final bool authenticated = await _dataService!.isAuthenticated();
    if (authenticated) {
      final userId = _dataService!.getCurrentUserId();
      if (userId != null) {
        await _loadUserProfile(userId);
      } else {
        _updateStatus(AuthStatus.unauthenticated);
      }
    } else {
      _updateStatus(AuthStatus.unauthenticated);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    if (_dataService == null) return false;
    _startLoading();
    try {
      final userId = await _dataService!.signIn(email: email, password: password);
      if (userId != null) {
        await _loadUserProfile(userId);
        _stopLoading();
        return true;
      }
      _stopLoading(error: 'Failed to sign in.');
      return false;
    } catch (e) {
      _stopLoading(error: e.toString());
      return false;
    }
  }
  
  // ADDED: This method handles the full sign-up flow.
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_dataService == null) return false;
    _startLoading(); // Notifies UI to show a loading indicator
    try {
      final userId = await _dataService!.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      // If signUp is successful, it returns a user ID.
      if (userId != null) {
        _stopLoading(successMessage: 'Registration successful! Please log in.');
        return true;
      }
      
      _stopLoading(error: 'Failed to create an account.');
      return false;
    } catch (e) {
      _stopLoading(error: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    if (_dataService == null) return;
    await _dataService!.signOut();
    _userProfile = null;
    _updateStatus(AuthStatus.unauthenticated);
  }

// MODIFIED: This method now returns a Future<bool> for better UI feedback.
  Future<bool> resetPassword({required String email}) async {
    if (_dataService == null) return false;
    _startLoading();
    try {
      await _dataService!.resetPassword(email: email);
      _stopLoading(error: 'Password reset email sent successfully.'); // Use the error message for success feedback too
      return true;
    } catch (e) {
      _stopLoading(error: e.toString());
      return false;
    }
  }

  Future<void> refreshUserProfile() async {
    if (currentUserId != null) {
      await _loadUserProfile(currentUserId!);
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final profileMap = await _dataService!.getUserProfile(userId: userId);
      if (profileMap != null) {
        _userProfile = UserProfile.fromMap(profileMap);
        _updateStatus(AuthStatus.authenticated);
      } else {
        // User is authenticated but has no profile document, treat as an error/unauthenticated state
        _userProfile = null;
        _updateStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _userProfile = null;
      _updateStatus(AuthStatus.unauthenticated);
    }
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  // Also, add a 'successMessage' parameter to your _stopLoading method
  void _stopLoading({String? error, String? successMessage}) {
    _isLoading = false;
    // Use the error message property to also convey success messages for SnackBars
    _errorMessage = error ?? successMessage;
    notifyListeners();
  }
  
  void _updateStatus(AuthStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }
}