import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart' as domain;
import 'package:hoque_family_chores/domain/entities/family.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';

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
    dueDate: DateTime(2020, 12, 31),
    createdAt: DateTime(2020, 1, 1),
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

class TestHelpers {
  static ProviderContainer createTestContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(overrides: overrides);
  }

  static Widget createTestApp({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(home: child),
    );
  }
}

void main() {
  group('Unit Tests', () {
    test('TestData has valid test user', () {
      expect(TestData.testUser.id.value, 'test_user_id');
      expect(TestData.testUser.name, 'Test User');
      expect(TestData.testUser.points.value, 100);
    });

    test('TestData has valid test family', () {
      expect(TestData.testFamily.id.value, 'test_family_id');
      expect(TestData.testFamily.name, 'Test Family');
    });

    test('TestData has valid test task', () {
      expect(TestData.testTask.id.value, 'test_task_id');
      expect(TestData.testTask.title, 'Test Task');
      expect(TestData.testTask.points.value, 10);
      expect(TestData.testTask.status, TaskStatus.available);
    });

    test('TestData has valid test task summary', () {
      expect(TestData.testTaskSummary.totalTasks, 5);
      expect(TestData.testTaskSummary.completedTasks, 3);
      expect(TestData.testTaskSummary.completionPercentage, 60);
    });
  });

  group('Widget Tests', () {
    testWidgets('TestHelpers creates valid test app', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHelpers.createTestApp(
          child: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
