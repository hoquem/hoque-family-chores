// lib/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/services/data_service.dart';

/// Simple User class for compatibility
class User {
  final String uid;
  final String? email;
  final String? displayName;

  User({
    required this.uid,
    this.email,
    this.displayName,
  });
}

/// Authentication states that the UI can react to
enum AuthStatus {
  /// Initial state, authentication status unknown
  initial,
  
  /// Authentication in progress
  authenticating,
  
  /// User is authenticated
  authenticated,
  
  /// User is not authenticated
  unauthenticated,
  
  /// Authentication failed
  error
}

/// Provider that manages authentication state and operations
class AuthProvider with ChangeNotifier {
  // Private fields
  DataService? _dataService;
  String? _userId;
  String? _userEmail;
  String? _displayName;
  String? _photoUrl;
  String? _errorMessage;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  
  // Getters
  /// Current authentication status
  AuthStatus get status => _status;
  
  /// Whether the user is logged in
  bool get isLoggedIn => _userId != null;
  
  /// Whether authentication operations are in progress
  bool get isLoading => _isLoading;
  
  /// Current error message, if any
  String? get errorMessage => _errorMessage;
  
  /// Current user ID
  String? get userId => _userId;
  
  /// Current user email
  String? get userEmail => _userEmail;
  
  /// Current user display name
  String? get displayName => _displayName;
  
  /// Current user photo URL
  String? get photoUrl => _photoUrl;

  /// Current user object (for compatibility with gamification screen)
  User? get currentUser {
    if (_userId != null) {
      return User(
        uid: _userId!,
        email: _userEmail,
        displayName: _displayName,
      );
    }
    return null;
  }
  
  /// Updates the data service reference
  /// This is called by the ChangeNotifierProxyProvider in main.dart
  void updateDataService(DataService dataService) {
    _dataService = dataService;
    _checkCurrentAuthState();
  }
  
  /// Constructor
  AuthProvider() {
    _checkCurrentAuthState();
  }
  
  /// Checks the current authentication state
  Future<void> _checkCurrentAuthState() async {
    if (_dataService == null) return;
    
    try {
      final isAuthenticated = await _dataService!.isAuthenticated();
      
      if (isAuthenticated) {
        _userId = _dataService!.getCurrentUserId();
        
        if (_userId != null) {
          final userProfile = await _dataService!.getUserProfile(userId: _userId!);
          
          if (userProfile != null) {
            _userEmail = userProfile['email'];
            _displayName = userProfile['displayName'];
            _photoUrl = userProfile['photoUrl'];
          }
          
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _handleError(e);
    }
    
    notifyListeners();
  }
  
  /// Signs in a user with email and password
  Future<bool> signIn({required String email, required String password}) async {
    if (_dataService == null) {
      _handleError('Data service not initialized');
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();
    
    try {
      final userId = await _dataService!.signIn(
        email: email,
        password: password,
      );
      
      if (userId != null) {
        _userId = userId;
        
        final userProfile = await _dataService!.getUserProfile(userId: userId);
        
        if (userProfile != null) {
          _userEmail = userProfile['email'];
          _displayName = userProfile['displayName'];
          _photoUrl = userProfile['photoUrl'];
        }
        
        _status = AuthStatus.authenticated;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _handleError('Sign in failed');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    }
  }
  
  /// Signs up a new user with email and password
  Future<bool> signUp({
    required String email, 
    required String password, 
    required String displayName
  }) async {
    if (_dataService == null) {
      _handleError('Data service not initialized');
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;
    _status = AuthStatus.authenticating;
    notifyListeners();
    
    try {
      final userId = await _dataService!.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (userId != null) {
        _userId = userId;
        _userEmail = email;
        _displayName = displayName;
        
        _status = AuthStatus.authenticated;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _handleError('Sign up failed');
        return false;
      }
    } catch (e) {
      _handleError(e);
      return false;
    }
  }
  
  /// Signs out the current user
  Future<void> signOut() async {
    if (_dataService == null) return;
    
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _dataService!.signOut();
      _userId = null;
      _userEmail = null;
      _displayName = null;
      _photoUrl = null;
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _handleError(e);
    }
    
    _setLoading(false);
    notifyListeners();
  }
  
  /// Sends a password reset email
  Future<bool> resetPassword({required String email}) async {
    if (_dataService == null) {
      _handleError('Data service not initialized');
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _dataService!.resetPassword(email: email);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }
  
  /// Updates the user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    FamilyRole? role,
    String? familyId,
  }) async {
    if (_dataService == null || _userId == null) {
      _handleError('User not authenticated');
      return false;
    }
    
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _dataService!.createOrUpdateUserProfile(
        userId: _userId!,
        displayName: displayName ?? _displayName ?? '',
        email: _userEmail ?? '',
        photoUrl: photoUrl,
        role: role,
        familyId: familyId,
      );
      
      if (displayName != null) {
        _displayName = displayName;
      }
      
      if (photoUrl != null) {
        _photoUrl = photoUrl;
      }
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }
  
  /// Refreshes the user profile data
  Future<void> refreshUserProfile() async {
    if (_dataService == null || _userId == null) return;
    
    try {
      final userProfile = await _dataService!.getUserProfile(userId: _userId!);
      
      if (userProfile != null) {
        _userEmail = userProfile['email'];
        _displayName = userProfile['displayName'];
        _photoUrl = userProfile['photoUrl'];
        notifyListeners();
      }
    } catch (e) {
      // Silently handle error, don't update UI
      if (kDebugMode) {
        print('Error refreshing user profile: $e');
      }
    }
  }
  
  /// Handles authentication errors
  void _handleError(dynamic error) {
    _status = AuthStatus.error;
    
    if (error is String) {
      _errorMessage = error;
    } else if (error is Exception) {
      _errorMessage = error.toString().replaceAll('Exception: ', '');
    } else {
      _errorMessage = 'An unexpected error occurred';
    }
    
    if (kDebugMode) {
      print('Auth error: $_errorMessage');
    }
    
    _setLoading(false);
    notifyListeners();
  }
  
  /// Updates the loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Clears any error messages
  void clearError() {
    _errorMessage = null;
    if (_status == AuthStatus.error) {
      _status = isLoggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
