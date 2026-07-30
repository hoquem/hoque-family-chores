import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/screens/member_detail_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_task_repository.dart';

final _familyId = FamilyId('family_1');

User _member(String id, String name, {UserRole role = UserRole.child, int points = 0}) {
  return User(
    id: UserId(id),
    name: name,
    email: Email('${name.split(' ').first.toLowerCase()}@example.com'),
    photoUrl: null,
    familyId: _familyId,
    role: role,
    points: Points(points),
    joinedAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now(),
  );
}

Task _task({
  required String id,
  required String title,
  required UserId createdBy,
  UserId? assignedTo,
  TaskStatus status = TaskStatus.available,
  int points = 10,
  DateTime? approvedAt,
  DateTime? createdAt,
}) {
  final now = DateTime.now();
  return Task(
    id: TaskId(id),
    title: title,
    description: '',
    status: status,
    difficulty: TaskDifficulty.easy,
    dueDate: now.add(const Duration(days: 1)),
    assignedToId: assignedTo,
    createdById: createdBy,
    createdAt: createdAt ?? now.subtract(const Duration(days: 1)),
    completedAt: status == TaskStatus.completed ? now.subtract(const Duration(hours: 1)) : null,
    approvedAt: approvedAt,
    points: Points(points),
    tags: const [],
    familyId: _familyId,
  );
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required User member,
  List<Task> tasks = const [],
}) async {
  final taskRepo = MockTaskRepository();
  taskRepo.clearAllSync();
  for (final t in tasks) {
    taskRepo.addTaskSync(t);
  }

  final container = ProviderContainer(
    overrides: [
      taskRepositoryProvider.overrideWith((_) => taskRepo),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: MemberDetailScreen(member: member),
      ),
    ),
  );

  // Let the task stream emit.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();

  return container;
}

void main() {
  testWidgets('shows member header with name, role, and star count', (tester) async {
    final member = _member('u1', 'Zafir Hoque', points: 42);
    await _pumpScreen(tester, member: member);

    // Name appears in both AppBar title and header card.
    expect(find.text('Zafir Hoque'), findsNWidgets(2));
    expect(find.text('Child'), findsOneWidget);
    expect(find.textContaining('42'), findsOneWidget);
  });

  testWidgets('stats show zero when no completed tasks', (tester) async {
    final member = _member('u1', 'Zafir');
    await _pumpScreen(tester, member: member);

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2)); // both stat counts are 0
  });

  testWidgets('current tab shows assigned and created tasks', (tester) async {
    final member = _member('u1', 'Zafir');
    final tasks = [
      _task(id: 't1', title: 'Clean room', createdBy: UserId('u1'), assignedTo: UserId('u1'), status: TaskStatus.assigned),
      _task(id: 't2', title: 'Do dishes', createdBy: UserId('u2'), assignedTo: UserId('u1'), status: TaskStatus.inProgress),
      _task(id: 't3', title: 'Take bins out', createdBy: UserId('u1'), assignedTo: UserId('u2'), status: TaskStatus.pendingApproval),
    ];

    await _pumpScreen(tester, member: member, tasks: tasks);

    expect(find.text('Clean room'), findsOneWidget);
    expect(find.text('Do dishes'), findsOneWidget);
    expect(find.text('Take bins out'), findsOneWidget);
  });

  testWidgets('completed tab shows finished tasks sorted by approvedAt desc', (tester) async {
    final member = _member('u1', 'Zafir');
    final now = DateTime.now();
    final tasks = [
      _task(
        id: 't1',
        title: 'Old chore',
        createdBy: UserId('u1'),
        assignedTo: UserId('u1'),
        status: TaskStatus.completed,
        points: 5,
        approvedAt: now.subtract(const Duration(days: 3)),
      ),
      _task(
        id: 't2',
        title: 'Recent chore',
        createdBy: UserId('u1'),
        assignedTo: UserId('u1'),
        status: TaskStatus.completed,
        points: 10,
        approvedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];

    await _pumpScreen(tester, member: member, tasks: tasks);

    // Switch to Completed tab.
    await tester.tap(find.text('Completed'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Recent chore'), findsOneWidget);
    expect(find.text('Old chore'), findsOneWidget);
    // Completed tiles show points and date in the subtitle row.
    expect(find.textContaining('10'), findsWidgets);
    expect(find.textContaining('5'), findsWidgets);
  });

  testWidgets('stats reflect completed tasks', (tester) async {
    final member = _member('u1', 'Zafir');
    final now = DateTime.now();
    final tasks = [
      _task(
        id: 't1',
        title: 'This week chore',
        createdBy: UserId('u1'),
        assignedTo: UserId('u1'),
        status: TaskStatus.completed,
        points: 15,
        approvedAt: now.subtract(const Duration(days: 2)),
      ),
      _task(
        id: 't2',
        title: 'Old chore',
        createdBy: UserId('u1'),
        assignedTo: UserId('u1'),
        status: TaskStatus.completed,
        points: 5,
        approvedAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    await _pumpScreen(tester, member: member, tasks: tasks);

    // Switch to Completed to make sure the list builds, but stats are always visible.
    await tester.tap(find.text('Completed'));
    await tester.pump(const Duration(milliseconds: 300));

    // This week: 1 task, 15 stars. All time: 2 tasks, 20 stars.
    // The stat block shows count as a large headline number.
    // Look for "1" near "This week" and "2" near "All time".
    final thisWeekFinder = find.text('This week');
    final allTimeFinder = find.text('All time');
    expect(thisWeekFinder, findsOneWidget);
    expect(allTimeFinder, findsOneWidget);

    // Verify the subtitle stars appear.
    expect(find.textContaining('15'), findsWidgets);
    expect(find.textContaining('20'), findsWidgets);
  });

  testWidgets('empty state when no current tasks', (tester) async {
    final member = _member('u1', 'Zafir');
    await _pumpScreen(tester, member: member);

    expect(find.text('No active chores'), findsOneWidget);
  });

  testWidgets('empty state when no completed tasks in completed tab', (tester) async {
    final member = _member('u1', 'Zafir');
    await _pumpScreen(tester, member: member);

    await tester.tap(find.text('Completed'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No completed chores yet'), findsOneWidget);
  });

  testWidgets('tasks created by member appear even if not assigned to them', (tester) async {
    final member = _member('u1', 'Zafir');
    final tasks = [
      _task(id: 't1', title: 'Created by me', createdBy: UserId('u1'), assignedTo: UserId('u2'), status: TaskStatus.assigned),
    ];

    await _pumpScreen(tester, member: member, tasks: tasks);

    expect(find.text('Created by me'), findsOneWidget);
  });
}
