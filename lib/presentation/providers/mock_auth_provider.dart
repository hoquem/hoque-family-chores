import 'package:flutter/material.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_auth_service.dart';
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';
import 'auth_provider_base.dart';

class MockAuthProvider extends AuthProviderBase {
  final GamificationServiceInterface? _gamificationService;
  final UserProfileServiceInterface? _userProfileService;
  final MockAuthService _mockAuthService;

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
  String? get userEmail => 'test@example.com';

  MockAuthProvider({
    MockAuthService? mockAuthService,
    GamificationServiceInterface? gamificationService,
    UserProfileServiceInterface? userProfileService,
  })  : _mockAuthService = mockAuthService ?? MockAuthService(),
        _gamificationService = gamificationService,
        _userProfileService = userProfileService {
    _initAuthStatus();
  }

  Future<void> _initAuthStatus() async {
    _setStatus(AuthStatus.unauthenticated);
    _isLoading = false;
    notifyListeners();
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    logger.i("[MockAuthProvider] Simulating sign-in for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate successful sign-in with mock data
    final now = DateTime.now();
    final mockMember = FamilyMember(
      id: MockData.childUserId1,
      userId: MockData.childUserId1,
      familyId: MockData.familyId,
      name: 'Zahra Hoque',
      photoUrl: 'https://i.pravatar.cc/150?u=zahra',
      role: FamilyRole.child,
      points: 850,
      joinedAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    _currentUserProfile = UserProfile(
      id: MockData.childUserId1,
      member: mockMember,
      points: 850,
      badges: [],
      achievements: [],
      createdAt: DateTime.now().subtract(const Duration(days: 150)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      completedTasks: [],
      inProgressTasks: [],
      availableTasks: [],
      preferences: {},
      statistics: {},
    );
    _userFamilyId = MockData.familyId;
    _setStatus(AuthStatus.authenticated);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    logger.i("[MockAuthProvider] Simulating sign-up for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate successful sign-up with mock data
    final now = DateTime.now();
    final mockMember = FamilyMember(
      id: MockData.childUserId1,
      userId: MockData.childUserId1,
      familyId: MockData.familyId,
      name: displayName ?? 'Zahra Hoque',
      photoUrl: 'https://i.pravatar.cc/150?u=zahra',
      role: FamilyRole.child,
      points: 850,
      joinedAt: now,
      updatedAt: now,
    );
    _currentUserProfile = UserProfile(
      id: MockData.childUserId1,
      member: mockMember,
      points: 850,
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
    _userFamilyId = MockData.familyId;
    _setStatus(AuthStatus.authenticated);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    logger.i("[MockAuthProvider] Simulating sign-out.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _currentUserProfile = null;
    _userFamilyId = null;
    _setStatus(AuthStatus.unauthenticated);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshUserProfile() async {
    logger.i("[MockAuthProvider] Simulating refresh user profile.");
    // No-op for mock
    notifyListeners();
  }

  Future<void> resetPassword({required String email}) async {
    logger.i("[MockAuthProvider] Simulating password reset for $email.");
    _setStatus(AuthStatus.authenticating);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate successful password reset
    logger.i("[MockAuthProvider] Password reset email sent successfully to $email.");
    _setStatus(AuthStatus.unauthenticated);
    _isLoading = false;
    notifyListeners();
  }
} 