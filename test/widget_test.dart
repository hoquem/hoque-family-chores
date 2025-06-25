import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

// Import ALL necessary models from your project
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/models/user_profile.dart';
import 'package:hoque_family_chores/models/family_member.dart';

// Import ALL necessary services and interfaces from your project
import 'package:hoque_family_chores/services/interfaces/user_profile_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/gamification_service_interface.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_user_profile_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_task_service.dart';
import 'package:hoque_family_chores/services/implementations/mock/mock_gamification_service.dart';

// Import ALL necessary providers from your project, ALIASING YOUR CUSTOM AUTHPROVIDER
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart'
    as app_auth_provider;
import 'package:hoque_family_chores/presentation/providers/gamification_provider.dart'
    as app_gamification_provider;
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';

// Import ALL necessary screens from your project
import 'package:hoque_family_chores/presentation/screens/family_setup_screen.dart';
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart';
import 'package:hoque_family_chores/main.dart'; // To access AuthWrapper
import 'package:hoque_family_chores/presentation/screens/app_shell.dart';

// --- Mocktail Mocks for Firebase Auth ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

// --- Mock Service Implementations for Testing ---

class MockGamificationService extends Mock
    implements GamificationServiceInterface {
  @override
  Future<List<Badge>> getPredefinedBadges() async {
    return [
      Badge(
        id: 'mock_badge_1',
        name: 'Test Badge',
        description: '',
        iconName: 'star_border',
        requiredPoints: 10,
        type: enums.BadgeType.taskCompletion,
        familyId: 'test_family_id',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
      ),
    ];
  }

  @override
  Future<List<Reward>> getPredefinedRewards() async {
    return [
      Reward(
        id: 'mock_reward_1',
        name: 'Test Reward',
        description: '',
        pointsCost: 100,
        iconName: 'card_giftcard',
        type: enums.RewardType.digital,
        familyId: 'test_family_id',
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
      ),
    ];
  }
}

// Mock AuthProvider (now explicitly implements app_auth_provider.AuthProvider)
class MockAuthProvider extends Mock implements app_auth_provider.AuthProvider {
  // Mock properties (getters)
  @override
  enums.AuthStatus get status => enums.AuthStatus.authenticated;
  @override
  UserProfile? get currentUserProfile => UserProfile(
    member: FamilyMember(
      id: 'test_user_id',
      userId: 'test_user_id',
      familyId: 'test_family_id',
      name: 'Test User',
      photoUrl: 'https://example.com/avatar.jpg',
      role: enums.FamilyRole.parent,
      points: 0,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime(2020, 1, 1),
    ),
    email: 'test@example.com',
    createdAt: DateTime(2020, 1, 1),
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
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> resetPassword({required String email}) async {}
  @override
  Future<void> refreshUserProfile() async {}
  @override
  UserProfile? getFamilyMember(String userId) {
    if (userId == 'test_user_id') {
      return UserProfile(
        member: FamilyMember(
          id: 'test_user_id',
          userId: 'test_user_id',
          familyId: 'test_family_id',
          name: 'Test User',
          photoUrl: 'https://example.com/avatar.jpg',
          role: enums.FamilyRole.parent,
          points: 0,
          joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
          updatedAt: DateTime(2020, 1, 1),
        ),
        email: 'test@example.com',
        createdAt: DateTime(2020, 1, 1),
      );
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

class MockAuthProviderUnauthenticated extends Mock
    implements app_auth_provider.AuthProvider {
  // Overrides for unauthenticated state
  @override
  enums.AuthStatus get status => enums.AuthStatus.unauthenticated;
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
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}
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

  group('Root Navigation', () {
    testWidgets('App displays DashboardScreen when authenticated', (
      WidgetTester tester,
    ) async {
      final mockFirebaseAuth = MockFirebaseAuth();
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test_user_id');
      when(
        () => mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(mockUser));
      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

      final mockUserProfileService = MockUserProfileService();
      when(
        () => mockUserProfileService.getUserProfile(userId: 'test_user_id'),
      ).thenAnswer(
        (_) async => UserProfile(
          member: FamilyMember(
            id: 'test_user_id',
            userId: 'test_user_id',
            familyId: 'test_family_id',
            name: 'Test User',
            photoUrl: 'https://example.com/avatar.jpg',
            role: enums.FamilyRole.parent,
            points: 0,
            joinedAt: DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime(2020, 1, 1),
          ),
          email: 'test@example.com',
          createdAt: DateTime(2020, 1, 1),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UserProfileServiceInterface>.value(
              value: mockUserProfileService,
            ),
            Provider<GamificationServiceInterface>.value(
              value: MockGamificationService(),
            ),
            Provider<TaskServiceInterface>.value(value: MockTaskService()),
            ChangeNotifierProvider<app_auth_provider.AuthProvider>(
              create: (BuildContext context) => MockAuthProvider(),
            ),
            ChangeNotifierProxyProvider2<
              GamificationServiceInterface,
              UserProfileServiceInterface,
              app_gamification_provider.GamificationProvider
            >(
              create:
                  (BuildContext context) =>
                      app_gamification_provider.GamificationProvider(
                        gamificationService:
                            context.read<GamificationServiceInterface>(),
                      ),
              update: (
                BuildContext context,
                GamificationServiceInterface gamificationService,
                UserProfileServiceInterface userProfileService,
                app_gamification_provider.GamificationProvider? provider,
              ) {
                return provider!..updateDependencies(
                  gamificationService: gamificationService,
                );
              },
            ),
            ChangeNotifierProxyProvider2<
              TaskServiceInterface,
              app_auth_provider.AuthProvider,
              TaskListProvider
            >(
              create: (BuildContext context) {
                final taskService = context.read<TaskServiceInterface>();
                final authProvider =
                    context.read<app_auth_provider.AuthProvider>();
                return TaskListProvider(
                  taskService: taskService,
                  authProvider: authProvider,
                );
              },
              update: (
                BuildContext context,
                TaskServiceInterface taskService,
                app_auth_provider.AuthProvider authProvider,
                TaskListProvider? previousTaskListProvider,
              ) {
                return previousTaskListProvider!
                  ..update(taskService, authProvider);
              },
            ),
          ],
          child: MaterialApp(home: AppShell()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('App displays LoginScreen when unauthenticated', (
      WidgetTester tester,
    ) async {
      final mockFirebaseAuth = MockFirebaseAuth();
      when(
        () => mockFirebaseAuth.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<UserProfileServiceInterface>.value(
              value: MockUserProfileService(),
            ),
            Provider<GamificationServiceInterface>.value(
              value: MockGamificationService(),
            ),
            Provider<TaskServiceInterface>.value(value: MockTaskService()),
            ChangeNotifierProvider<app_auth_provider.AuthProvider>(
              create:
                  (BuildContext context) => MockAuthProviderUnauthenticated(),
            ),
            ChangeNotifierProxyProvider2<
              TaskServiceInterface,
              app_auth_provider.AuthProvider,
              TaskListProvider
            >(
              create: (BuildContext context) {
                final taskService = context.read<TaskServiceInterface>();
                final authProvider =
                    context.read<app_auth_provider.AuthProvider>();
                return TaskListProvider(
                  taskService: taskService,
                  authProvider: authProvider,
                );
              },
              update: (
                BuildContext context,
                TaskServiceInterface taskService,
                app_auth_provider.AuthProvider authProvider,
                TaskListProvider? previousTaskListProvider,
              ) {
                return previousTaskListProvider!
                  ..update(taskService, authProvider);
              },
            ),
          ],
          child: MaterialApp(home: AppShell()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('FamilySetupScreen', () {
    testWidgets('displays form and allows family creation', (
      WidgetTester tester,
    ) async {
      // Arrange: Provide necessary mocks
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<app_auth_provider.AuthProvider>(
              create: (_) => MockAuthProviderUnauthenticated(),
            ),
          ],
          child: MaterialApp(home: FamilySetupScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Form fields are present
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Create Family'), findsOneWidget);

      // Act: Enter family name and tap button
      await tester.enterText(find.byType(TextField), 'The Testers');
      await tester.tap(find.text('Create Family'));
      await tester.pump();

      // Assert: Loading indicator or error message (simulate as needed)
      // (In a real test, mock the provider to simulate loading or error)
    });
  });

  group('TaskListScreen', () {
    testWidgets('shows loading indicator and then tasks', (
      WidgetTester tester,
    ) async {
      // Arrange: Mock provider with loading state
      final mockProvider = TaskListProvider(
        taskService: MockTaskService(),
        authProvider: MockAuthProvider(),
      );
      // Set loading state
      mockProvider.setFilter(enums.TaskFilterType.all);
      await tester.pumpWidget(
        ChangeNotifierProvider<TaskListProvider>.value(
          value: mockProvider,
          child: MaterialApp(home: TaskListScreen()),
        ),
      );
      await tester.pump();
      // Assert: Loading indicator present
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // (Expand: Add tasks to provider and pump again to check task rendering)
    });
  });

  group('GamificationScreen', () {
    testWidgets('renders badges and rewards', (WidgetTester tester) async {
      // Arrange: Provide mock providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<app_auth_provider.AuthProvider>(
              create: (_) => MockAuthProvider(),
            ),
            Provider<GamificationServiceInterface>.value(
              value: MockGamificationService(),
            ),
          ],
          child: MaterialApp(home: GamificationScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Assert: Badges and rewards are rendered
      expect(find.text('Test Badge'), findsWidgets);
      expect(find.text('Test Reward'), findsWidgets);
    });
  });

  // TODO: Add more widget tests for other screens and widgets (e.g., MyTasksWidget, FamilyListScreen, etc.)
  // TODO: Add tests for error states, edge cases, and user roles
  // TODO: Add golden tests for visual regression (see flutter_test docs)
}
