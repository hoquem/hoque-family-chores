// The Timeline on a chore's details screen names the people, not just the
// dates. Trust is the product's model — parents may sign off their own chores —
// so the family has to be able to see who did what without inferring it.
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
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _me = UserId(_uid);
final _mum = UserId('mum');
final _amira = UserId('amira');
final _dad = UserId('dad');
final _familyId = FamilyId('family_1');

User _member(UserId id, String name, UserRole role) => User(
      id: id,
      name: name,
      // Keyed off the name, not the id: the signed-in uid has an underscore,
      // which Email rejects.
      email: Email('${name.toLowerCase()}@example.com'),
      familyId: _familyId,
      role: role,
      points: Points(0),
      joinedAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Task _task({
  TaskStatus status = TaskStatus.completed,
  UserId? createdById,
  UserId? submittedBy,
  UserId? approvedBy,
  UserId? rejectedBy,
  String? rejectionReason,
}) =>
    Task(
      id: TaskId('task1'),
      title: 'Hoover downstairs',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 20),
      assignedToId: submittedBy,
      createdById: createdById,
      createdAt: DateTime(2026, 8, 10, 9, 14),
      completedAt: submittedBy == null ? null : DateTime(2026, 8, 10, 16, 2),
      submittedBy: submittedBy,
      submittedAt: submittedBy == null ? null : DateTime(2026, 8, 10, 16, 2),
      approvedBy: approvedBy,
      approvedAt: approvedBy == null ? null : DateTime(2026, 8, 10, 18, 30),
      rejectedBy: rejectedBy,
      rejectedAt: rejectedBy == null ? null : DateTime(2026, 8, 10, 17, 0),
      rejectionReason: rejectionReason,
      points: Points(3),
      tags: const [],
      familyId: _familyId,
    );

/// Pumps TaskDetailsScreen signed in as [_me], with a roster whose names the
/// timeline has to resolve.
Future<void> _pump(WidgetTester tester, Task task) async {
  // 430x932 for the same reason task_details_actions_test uses it: the test
  // fallback font measures far wider than a real one and overflows the header.
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final families = MockFamilyRepository()
    ..addTestFamilyMembers(_familyId, [
      _member(_me, 'Yamin', UserRole.child),
      _member(_mum, 'Mum', UserRole.parent),
      _member(_amira, 'Amira', UserRole.child),
      _member(_dad, 'Dad', UserRole.parent),
    ]);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => families),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: TaskDetailsScreen(task: task),
      ),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(_me);
    await users.updateUserProfile(profile!.copyWith(familyId: _familyId));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('the timeline names people', () {
    testWidgets('says who added the chore', (tester) async {
      await _pump(tester, _task(createdById: _mum));
      expect(find.text('Added by Mum'), findsOneWidget);
    });

    testWidgets('says who did it and who checked it', (tester) async {
      await _pump(
        tester,
        _task(createdById: _mum, submittedBy: _amira, approvedBy: _dad),
      );
      expect(find.text('Done by Amira'), findsOneWidget);
      expect(find.text('Checked by Dad'), findsOneWidget);
    });

    testWidgets('calls the viewer "you" rather than by name', (tester) async {
      await _pump(tester, _task(createdById: _me));
      expect(find.text('Added by you'), findsOneWidget);
    });

    testWidgets('says who sent it back, and why', (tester) async {
      await _pump(
        tester,
        _task(
          status: TaskStatus.needsRevision,
          createdById: _mum,
          submittedBy: _amira,
          rejectedBy: _dad,
          rejectionReason: 'Under the sofa please',
        ),
      );
      expect(find.text('Sent back by Dad'), findsOneWidget);
      expect(find.textContaining('Under the sofa please'), findsOneWidget);
    });
  });

  group('a chore signed off by the person who did it', () {
    testWidgets('says so plainly', (tester) async {
      // Parents may approve their own chores by design. That is allowed, so
      // the note is neutral — but it is stated, because a family should not
      // have to notice the same name twice to know.
      await _pump(
        tester,
        _task(createdById: _dad, submittedBy: _dad, approvedBy: _dad),
      );
      expect(find.text('Checked by Dad'), findsOneWidget);
      expect(find.text('their own chore'), findsOneWidget);
    });

    testWidgets('says nothing of the sort when someone else checked it',
        (tester) async {
      await _pump(
        tester,
        _task(createdById: _mum, submittedBy: _amira, approvedBy: _dad),
      );
      expect(find.text('their own chore'), findsNothing);
    });
  });

  group('a chore with nothing on record', () {
    testWidgets('shows no approver row rather than inventing one',
        (tester) async {
      // Chores completed before approvedBy existed carry no approver.
      await _pump(tester, _task(createdById: _mum));
      expect(find.textContaining('Checked by'), findsNothing);
    });

    testWidgets('shows no creator row when nobody is on record',
        (tester) async {
      await _pump(tester, _task());
      expect(find.textContaining('Added by'), findsNothing);
    });
  });
}
