import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';

abstract class AuthProviderBase with ChangeNotifier {
  // Common getters
  UserProfile? get currentUserProfile;
  String? get currentUserId;
  String? get userFamilyId;
  String? get displayName;
  String? get photoUrl;
  bool get isLoggedIn;
  AuthStatus get status;
  String? get errorMessage;
  bool get isLoading;
  UserProfile? get currentUser;
  String? get userEmail;

  // Common methods
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  });
  Future<void> signOut();
  Future<void> refreshUserProfile();
  Future<void> resetPassword({required String email});
} 