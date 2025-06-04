// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false; // Simulate: user is initially not logged in

  bool get isLoggedIn => _isLoggedIn;

  // Simulate login
  Future<void> login(String email, String password) async {
    // In a real app, you'd call your auth service here
    // For now, just simulate a delay and successful login
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = true;
    notifyListeners();
  }

  // Simulate logout
  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = false;
    notifyListeners();
  }
}