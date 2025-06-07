// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';

/// Simple mock user class for development purposes
class MockUser {
  final String uid;
  final String email;
  final String displayName;

  MockUser({
    required this.uid,
    required this.email,
    this.displayName = '',
  });
}

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false; // Simulate: user is initially not logged in
  MockUser? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  MockUser? get currentUser => _currentUser;

  // Simulate login
  Future<void> login(String email, String password) async {
    // In a real app, you'd call your auth service here
    // For now, just simulate a delay and successful login
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a mock user with the provided email
    _currentUser = MockUser(
      uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: email.split('@').first, // Simple display name from email
    );
    
    _isLoggedIn = true;
    notifyListeners();
  }

  // Simulate logout
  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = false;
    _currentUser = null; // Clear the current user
    notifyListeners();
  }
}
