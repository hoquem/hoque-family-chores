import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hoque_family_chores/main.dart';

// Import domain entities
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';

// Import Riverpod providers
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_summary_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/my_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/leaderboard_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/gamification_notifier.dart';

// Import screens
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';
import 'package:hoque_family_chores/presentation/screens/app_shell.dart';
import 'package:hoque_family_chores/presentation/screens/task_list_screen.dart';
import 'package:hoque_family_chores/presentation/screens/gamification_screen.dart';
import 'package:hoque_family_chores/presentation/screens/family_setup_screen.dart';

// Import widgets
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';

// Import shared enums

// --- Mocktail Mocks for Firebase Auth ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

// --- Test Data ---
class TestData {
  static final User testUser = User(
    id: UserId('test_user_id'),
    name: 'Test User',
    email: Email('test@example.com'),
    photoUrl: 'https://example.com/avatar.jpg',
    familyId: FamilyId('test_family_id'),
    role: UserRole.parent,
    points: Points(100),
    joinedAt: DateTime(2020, 1, 1),
    updatedAt: DateTime(2020, 1, 1),
  );

  static final FamilyEntity testFamily = FamilyEntity(
    id: FamilyId('test_family_id'),
    name: 'Test Family',
    description: 'A test family',
    creatorId: UserId('test_user_id'),
    memberIds: [UserId('test_user_id')],
    createdAt: DateTime(2020, 1, 1),
    updatedAt: DateTime(2020, 1, 1),
  );

  static final Task testTask = Task(
    id: TaskId('test_task_id'),
    title: 'Test Task',
    description: 'A test task',
    points: Points(10),
    familyId: FamilyId('test_family_id'),
    status: TaskStatus.available,
    assignedTo: null,
    dueDate: null,
    createdAt: DateTime(2020, 1, 1),
    updatedAt: DateTime(2020, 1, 1),
  );

  static final Badge testBadge = Badge(
    id: BadgeId('test_badge_id'),
    name: 'Test Badge',
    description: 'A test badge',
    iconName: 'star',
    requiredPoints: Points(50),
    type: BadgeType.taskCompletion,
    rarity: BadgeRarity.common,
    familyId: FamilyId('test_family_id'),
    createdAt: DateTime(2020, 1, 1),
    updatedAt: DateTime(2020, 1, 1),
  );

  static final TaskSummary testTaskSummary = TaskSummary(
    totalTasks: 5,
    completedTasks: 3,
    pendingTasks: 1,
    availableTasks: 1,
    needsRevisionTasks: 0,
    assignedTasks: 1,
    dueToday: 0,
    pointsEarned: 30,
    completionPercentage: 60,
  );
}

// --- Test Helpers ---
class TestHelpers {
  static ProviderContainer createTestContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(
      overrides: overrides,
    );
  }

  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }
}

// --- Test Overrides ---
final mockAuthNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return MockAuthNotifier();
});

final mockTaskListNotifierProvider = StateNotifierProvider<TaskListNotifier, AsyncValue<List<Task>>>((ref) {
  return MockTaskListNotifier();
});

final mockTaskSummaryNotifierProvider = FutureProvider.family<TaskSummary, FamilyId>((ref, familyId) async {
  return TestData.testTaskSummary;
});

final mockAvailableTasksNotifierProvider = FutureProvider.family<List<Task>, FamilyId>((ref, familyId) async {
  return [TestData.testTask];
});

final mockMyTasksNotifierProvider = FutureProvider<List<Task>>((ref) async {
  return [TestData.testTask];
});

final mockLeaderboardNotifierProvider = FutureProvider.family<List<LeaderboardEntry>, FamilyId>((ref, familyId) async {
  return [];
});

final mockFamilyNotifierProvider = StateNotifierProvider<FamilyNotifier, AsyncValue<FamilyEntity?>>((ref) {
  return MockFamilyNotifier();
});

final mockGamificationNotifierProvider = StateNotifierProvider<GamificationNotifier, AsyncValue<GamificationState>>((ref) {
  return MockGamificationNotifier();
});

// --- Mock Notifiers ---
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier() : super(const AuthState());

  @override
  Future<void> signIn({required String email, required String password}) async {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: TestData.testUser,
      isLoading: false,
    );
  }

  @override
  Future<void> signUp({required String email, required String password, String? displayName}) async {
    state = AuthState(
      status: AuthStatus.authenticated,
      user: TestData.testUser,
      isLoading: false,
    );
  }

  @override
  Future<void> signOut() async {
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  @override
  Future<void> refreshUserProfile() async {
    // Mock implementation
  }
}

class MockTaskListNotifier extends StateNotifier<AsyncValue<List<Task>>> implements TaskListNotifier {
  MockTaskListNotifier() : super(const AsyncValue.loading());

  @override
  Future<void> refresh() async {
    state = AsyncValue.data([TestData.testTask]);
  }
}

class MockFamilyNotifier extends StateNotifier<AsyncValue<FamilyEntity?>> implements FamilyNotifier {
  MockFamilyNotifier() : super(const AsyncValue.loading());

  @override
  Future<void> createFamily({required String name, required String description}) async {
    state = AsyncValue.data(TestData.testFamily);
  }

  @override
  Future<void> addMember({required String email, required String role}) async {
    // Mock implementation
  }
}

class MockGamificationNotifier extends StateNotifier<AsyncValue<GamificationState>> implements GamificationNotifier {
  MockGamificationNotifier() : super(const AsyncValue.loading());

  @override
  Future<void> awardPoints({required String userId, required int points, required String reason}) async {
    // Mock implementation
  }

  @override
  Future<void> redeemReward({required String rewardId}) async {
    // Mock implementation
  }
}

// --- Test Cases ---
void main() {
  group('Widget Tests', () {
    testWidgets('Login screen shows login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const LoginScreen(),
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
          ],
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Task summary widget shows summary data', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const TaskSummaryWidget(),
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
            taskSummaryNotifierProvider.overrideWith((ref, familyId) async => TestData.testTaskSummary),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Task Summary'), findsOneWidget);
      expect(find.text('Total Tasks'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // totalTasks
    });

    testWidgets('Leaderboard widget shows leaderboard data', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const LeaderboardWidget(),
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
            leaderboardNotifierProvider.overrideWith((ref, familyId) async => []),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Leaderboard Data'), findsOneWidget);
    });

    testWidgets('My tasks widget shows tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MyTasksWidget(),
          overrides: [
            myTasksNotifierProvider.overrideWith((ref) async => [TestData.testTask]),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('10 points'), findsOneWidget);
    });
  });

  group('Provider Tests', () {
    test('AuthNotifier can sign in', () async {
      final container = TestHelpers.createTestContainer(
        overrides: [
          authNotifierProvider.overrideWith((ref) => MockAuthNotifier()),
        ],
      );

      final notifier = container.read(authNotifierProvider.notifier);
      await notifier.signIn(email: 'test@example.com', password: 'password');

      final state = container.read(authNotifierProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNotNull);
    });

    test('TaskListNotifier can refresh', () async {
      final container = TestHelpers.createTestContainer(
        overrides: [
          taskListNotifierProvider.overrideWith((ref) => MockTaskListNotifier()),
        ],
      );

      final notifier = container.read(taskListNotifierProvider.notifier);
      await notifier.refresh();

      final state = container.read(taskListNotifierProvider);
      expect(state.value, isNotNull);
      expect(state.value!.length, 1);
    });
  });
}
