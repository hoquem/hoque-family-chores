import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

// Import ALL necessary models from your project
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/enums.dart' as app_enums; // <--- Ensure this alias is consistent

// Import ALL necessary services and interfaces from your project
import 'package:hoque_family_chores/services/data_service_interface.dart' as app_data_service_interface;
import 'package:hoque_family_chores/services/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';
import 'package:hoque_family_chores/services/mock_data_service.dart';
import 'package:hoque_family_chores/services/mock_task_service.dart';

// Import ALL necessary providers from your project, ALIASING YOUR CUSTOM AUTHPROVIDER
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart' as app_auth_provider; // <--- Ensure this alias is consistent
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart' as app_gamification_provider;
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';

// Import ALL necessary screens from your project
import 'package:hoque_family_chores/presentation/screens/dashboard_screen.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/main.dart'; // To access AuthWrapper

// --- Mocktail Mocks for Firebase Auth ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockUserCredential extends Mock implements UserCredential {}

// --- Mock Service Implementations for Testing ---

class MockGamificationService extends Mock implements GamificationServiceInterface {
  @override
  Future<List<Badge>> getPredefinedBadges() async {
    return const [
      Badge(id: 'mock_badge_1', name: 'Test Badge', description: '', imageUrl: '', category: app_enums.BadgeCategory.taskMaster, rarity: app_enums.BadgeRarity.common),
    ];
  }

  @override
  Future<List<Reward>> getPredefinedRewards() async {
    return const [
      Reward(id: 'mock_reward_1', title: 'Test Reward', description: '', pointsCost: 100, iconName: '', category: app_enums.RewardCategory.digital, rarity: app_enums.RewardRarity.common),
    ];
  }
}

// Mock AuthProvider (now explicitly implements app_auth_provider.AuthProvider)
// This forces all methods/getters to be defined, resolving override issues and constructor chaining.
class MockAuthProvider extends Mock implements app_auth_provider.AuthProvider {
  // Mock properties (getters)
  @override
  app_enums.AuthStatus get status => app_enums.AuthStatus.authenticated; // Use aliased enum
  @override
  UserProfile? get currentUserProfile => UserProfile( // Removed const
        id: 'test_user_id',
        name: 'Test User',
        email: 'test@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
        role: app_enums.FamilyRole.parent, // Use aliased enum
        familyId: 'test_family_id',
        joinedAt: (DateTime.fromMillisecondsSinceEpoch(0)),
      );
  @override
  String? get currentUserId => 'test_user_id';
  @override
  String? get userFamilyId => 'test_family_id';
  @override
  String? get displayName => 'Test User';
  @override
  String? get photoUrl => 'https://example.com/avatar.jpg';
  @override
  String? get userEmail => 'test@example.com';
  @override
  bool get isLoggedIn => true;
  @override
  String? get errorMessage => null;
  @override
  bool get isLoading => false;

  // Mock methods (must be defined as per the interface)
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> resetPassword({required String email}) async {}
  @override
  Future<void> refreshUserProfile() async {}
  @override
  UserProfile? getFamilyMember(String userId) {
    if (userId == 'test_user_id') {
      return UserProfile( // Removed const
          id: 'test_user_id',
          name: 'Test User',
          joinedAt: (DateTime.fromMillisecondsSinceEpoch(0)));
    }
    return null;
  }
  @override
  bool get hasListeners => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void dispose() {}
  @override
  void notifyListeners() {}
}

class MockAuthProviderUnauthenticated extends Mock implements app_auth_provider.AuthProvider {
  // Overrides for unauthenticated state
  @override
  app_enums.AuthStatus get status => app_enums.AuthStatus.unauthenticated; // Use aliased enum
  @override
  UserProfile? get currentUserProfile => null;
  @override
  String? get currentUserId => null;
  @override
  String? get userFamilyId => null;
  @override
  String? get displayName => null;
  @override
  String? get photoUrl => null;
  @override
  String? get userEmail => null;
  @override
  bool get isLoggedIn => false;
  @override
  String? get errorMessage => null;
  @override
  bool get isLoading => false;

  // All methods must be explicitly mocked
  @override
  Future<void> signIn({required String email, required String password}) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> resetPassword({required String email}) async {}
  @override
  Future<void> refreshUserProfile() async {}
  @override
  UserProfile? getFamilyMember(String userId) => null;
  @override
  bool get hasListeners => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  void dispose() {}
  @override
  void notifyListeners() {}
}

// --- Main Test Suite ---
void main() {
  setUpAll(() {
    registerFallbackValue(MockFirebaseAuth());
  });

  testWidgets('App displays DashboardScreen when authenticated', (WidgetTester tester) async {
    final mockFirebaseAuth = MockFirebaseAuth();
    final mockUser = MockUser();
    when(() => mockUser.uid).thenReturn('test_user_id');
    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(mockUser));
    when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

    final mockDataService = MockDataService();
    when(() => mockDataService.getUserProfile(userId: 'test_user_id'))
        .thenAnswer((_) async => UserProfile( // Removed const
              id: 'test_user_id',
              name: 'Test User',
              email: 'test@example.com',
              joinedAt: (DateTime.fromMillisecondsSinceEpoch(0)),
            ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<app_data_service_interface.DataServiceInterface>.value(value: mockDataService),
          Provider<GamificationServiceInterface>.value(value: MockGamificationService()),
          Provider<TaskServiceInterface>.value(value: MockTaskService()),
          ChangeNotifierProvider<app_auth_provider.AuthProvider>(
            create: (BuildContext context) => MockAuthProvider(),
          ),
          ChangeNotifierProxyProvider2<GamificationServiceInterface, app_data_service_interface.DataServiceInterface, app_gamification_provider.GamificationProvider>(
            create: (BuildContext context) => app_gamification_provider.GamificationProvider(),
            update: (
              BuildContext context,
              GamificationServiceInterface gamificationService,
              app_data_service_interface.DataServiceInterface dataService,
              app_gamification_provider.GamificationProvider? provider,
            ) {
              return provider!..updateDependencies(
                gamificationService: gamificationService,
                dataService: dataService,
              );
            },
          ),
          ChangeNotifierProxyProvider<app_auth_provider.AuthProvider, TaskListProvider>(
            create: (BuildContext context) => TaskListProvider(),
            update: (
              BuildContext context,
              app_auth_provider.AuthProvider authProvider,
              TaskListProvider? taskListProvider,
            ) {
              final taskService = context.read<TaskServiceInterface>();
              return taskListProvider!..update(taskService, authProvider);
            },
          ),
        ],
        child: MaterialApp( // <--- REMOVED const
          home: AuthWrapper(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('App displays LoginScreen when unauthenticated', (WidgetTester tester) async {
    final mockFirebaseAuth = MockFirebaseAuth();
    when(() => mockFirebaseAuth.authStateChanges())
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<app_data_service_interface.DataServiceInterface>.value(value: MockDataService()),
          Provider<GamificationServiceInterface>.value(value: MockGamificationService()),
          Provider<TaskServiceInterface>.value(value: MockTaskService()),
          ChangeNotifierProvider<app_auth_provider.AuthProvider>(
            create: (BuildContext context) => MockAuthProviderUnauthenticated(),
          ),
          ChangeNotifierProxyProvider<app_auth_provider.AuthProvider, TaskListProvider>(
            create: (BuildContext context) => TaskListProvider(),
            update: (
              BuildContext context,
              app_auth_provider.AuthProvider authProvider,
              TaskListProvider? taskListProvider,
            ) {
              final taskService = context.read<TaskServiceInterface>();
              return taskListProvider!..update(taskService, authProvider);
            },
          ),
        ],
        child: MaterialApp( // <--- REMOVED const
          home: AuthWrapper(),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}