import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import domain entities
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/badge.dart';
import 'package:hoque_family_chores/domain/entities/user.dart' as domain;
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/shared_enums.dart';

// Import Riverpod providers
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_summary_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/my_tasks_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/leaderboard_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart'
    as family_notifier;
import 'package:hoque_family_chores/presentation/providers/riverpod/gamification_notifier.dart';

// Import screens
import 'package:hoque_family_chores/presentation/screens/login_screen.dart';

// Import widgets
import 'package:hoque_family_chores/presentation/widgets/task_summary_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/leaderboard_widget.dart';
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';

// --- Test Data ---
class TestData {
  static final domain.User testUser = domain.User(
    id: UserId('test_user_id'),
    name: 'Test User',
    email: Email('test@example.com'),
    photoUrl: 'https://example.com/avatar.jpg',
    familyId: FamilyId('test_family_id'),
    role: domain.UserRole.parent,
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
    difficulty: TaskDifficulty.easy,
    tags: const [],
    dueDate: DateTime(2025, 12, 31),
    createdAt: DateTime(2020, 1, 1),
  );

  static final Badge testBadge = Badge(
    id: 'test_badge_id',
    name: 'Test Badge',
    description: 'A test badge',
    iconName: 'star',
    requiredPoints: Points(50),
    type: BadgeType.taskCompletion,
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

// --- Test Cases ---
void main() {
  group('Widget Tests', () {
    testWidgets('Login screen shows login form', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const LoginScreen(),
          overrides: [
            authNotifierProvider.overrideWith(() => _TestAuthNotifier()),
          ],
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('My tasks widget shows login prompt when not authenticated',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const MyTasksWidget(),
          overrides: [
            authNotifierProvider.overrideWith(() => _TestAuthNotifier()),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Please log in to see your tasks.'), findsOneWidget);
    });
  });

  group('Data Model Tests', () {
    test('Task entity has correct properties', () {
      final task = TestData.testTask;
      expect(task.id.value, 'test_task_id');
      expect(task.title, 'Test Task');
      expect(task.status, TaskStatus.available);
      expect(task.points.value, 10);
      expect(task.familyId.value, 'test_family_id');
      expect(task.difficulty, TaskDifficulty.easy);
      expect(task.tags, isEmpty);
    });

    test('User entity has correct properties', () {
      final user = TestData.testUser;
      expect(user.id.value, 'test_user_id');
      expect(user.name, 'Test User');
      expect(user.email.value, 'test@example.com');
      expect(user.role, domain.UserRole.parent);
      expect(user.points.value, 100);
    });

    test('FamilyEntity has correct properties', () {
      final family = TestData.testFamily;
      expect(family.id.value, 'test_family_id');
      expect(family.name, 'Test Family');
      expect(family.memberIds.length, 1);
      expect(family.hasMember(UserId('test_user_id')), isTrue);
    });

    test('Badge entity has correct properties', () {
      final badge = TestData.testBadge;
      expect(badge.id, 'test_badge_id');
      expect(badge.name, 'Test Badge');
      expect(badge.type, BadgeType.taskCompletion);
    });

    test('TaskSummary has correct computed properties', () {
      final summary = TestData.testTaskSummary;
      expect(summary.totalTasks, 5);
      expect(summary.completedTasks, 3);
      expect(summary.completionPercentage, 60);
      expect(summary.totalCompleted, 3);
    });

    test('AuthStatus enum has expected values', () {
      expect(AuthStatus.initial, isNotNull);
      expect(AuthStatus.authenticated, isNotNull);
      expect(AuthStatus.unauthenticated, isNotNull);
      expect(AuthStatus.authenticating, isNotNull);
      expect(AuthStatus.error, isNotNull);
    });

    test('AuthState defaults are correct', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
    });

    test('AuthState copyWith works', () {
      const state = AuthState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        user: TestData.testUser,
        isLoading: false,
      );
      expect(updated.status, AuthStatus.authenticated);
      expect(updated.user, isNotNull);
      expect(updated.isLoading, isFalse);
    });

    test('Task copyWith works', () {
      final task = TestData.testTask;
      final updated = task.copyWith(
        status: TaskStatus.completed,
        completedAt: DateTime.now(),
      );
      expect(updated.status, TaskStatus.completed);
      expect(updated.completedAt, isNotNull);
      expect(updated.title, 'Test Task'); // Unchanged fields preserved
    });

    test('Points arithmetic works', () {
      final a = Points(10);
      final b = Points(5);
      expect(a.add(b).value, 15);
      expect(a.subtract(b).value, 5);
      expect(a.multiply(2.0).value, 20);
      expect(a.isGreaterThan(b), isTrue);
      expect(b.isLessThan(a), isTrue);
    });
  });
}

/// A simple test-only AuthNotifier that starts in unauthenticated state.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}
