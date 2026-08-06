// The action section of TaskDetailsScreen.
//
// Written to close a verification gap: the screen was migrated to
// `taskActionsFor` while sitting at 0 covered lines, so the migration rested on
// reading the old conditions rather than running them. These pin what the
// screen actually renders per status — including button ORDER, which the
// extraction could have silently reversed with nothing to catch it.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
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
final _sibling = UserId('kid2');
final _familyId = FamilyId('family_1');

Task _task({
  required TaskStatus status,
  UserId? assignedToId,
  UserId? createdById,
  bool requiresPhotoProof = false,
}) =>
    Task(
      id: TaskId('task1'),
      title: 'Mop the kitchen floor',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime(2026, 8, 20),
      assignedToId: assignedToId,
      createdById: createdById ?? _sibling,
      createdAt: DateTime(2026, 8, 1),
      points: Points(10),
      tags: const [],
      familyId: _familyId,
      requiresPhotoProof: requiresPhotoProof,
    );

/// Pumps TaskDetailsScreen signed in as [_me] in family_1.
Future<void> _pump(
  WidgetTester tester, {
  required TaskStatus status,
  UserId? assignedToId,
  UserId? createdById,
  bool requiresPhotoProof = false,
}) async {
  // 430x932 (iPhone 16 Pro Max), not the 390x844 the other screen tests use.
  // At 390 the header's stars/due-date Row overflows by 27px — but only in
  // tests: flutter_test substitutes a fixed-width fallback font where every
  // glyph is roughly 1em wide, so "Aug 20, 2026" measures far wider here than
  // on a device. Checked before widening rather than "fixing" a Row that is
  // not broken. Anything that genuinely must fit a narrow phone belongs in a
  // dedicated fits-test with real fonts loaded, as add_task_effort_fits_test
  // does — these tests are about which actions appear, not layout.
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final users = MockUserRepository();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
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
        home: TaskDetailsScreen(
          task: _task(
            status: status,
            assignedToId: assignedToId,
            createdById: createdById,
            requiresPhotoProof: requiresPhotoProof,
          ),
        ),
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
  group('an unclaimed chore', () {
    testWidgets('someone else created can be claimed', (tester) async {
      await _pump(tester,
          status: TaskStatus.available, createdById: _sibling);
      expect(find.text("I'll do it!"), findsOneWidget);
    });

    testWidgets('I created cannot be claimed by me', (tester) async {
      await _pump(tester, status: TaskStatus.available, createdById: _me);
      expect(find.text("I'll do it!"), findsNothing);
    });
  });

  group('a chore assigned to me', () {
    testWidgets('offers Done, then a way to hand it back — in that order',
        (tester) async {
      await _pump(tester, status: TaskStatus.assigned, assignedToId: _me);

      final done = find.text("I've done it!");
      final back = find.text('Give it back');
      expect(done, findsOneWidget);
      expect(back, findsOneWidget);
      // Order matters and nothing else pins it: the old code emitted hand-back
      // from a separate block that ran after the status blocks, so the primary
      // action has always been on top.
      expect(tester.getTopLeft(done).dy, lessThan(tester.getTopLeft(back).dy));
    });

    testWidgets('must be started first when it needs photo proof',
        (tester) async {
      await _pump(tester,
          status: TaskStatus.assigned,
          assignedToId: _me,
          requiresPhotoProof: true);
      expect(find.text('Start (take before photo)'), findsOneWidget);
      expect(find.text("I've done it!"), findsNothing,
          reason: 'Done beside Start would let the before photo be skipped');
    });

    testWidgets('says which photo is wanted once started', (tester) async {
      await _pump(tester,
          status: TaskStatus.inProgress,
          assignedToId: _me,
          requiresPhotoProof: true);
      expect(find.text("I've done it! (take after photo)"), findsOneWidget);
      expect(find.text('Give it back'), findsOneWidget);
    });
  });

  group('a chore sent back to me', () {
    testWidgets('can be resubmitted or handed back', (tester) async {
      await _pump(tester,
          status: TaskStatus.needsRevision, assignedToId: _me);
      expect(find.text('Send again'), findsOneWidget);
      expect(find.text('Give it back'), findsOneWidget);
      expect(find.text("I've done it!"), findsNothing,
          reason: 'a sent-back chore resubmits, it does not complete afresh');
    });
  });

  group('a chore waiting for sign-off', () {
    testWidgets('someone else did can be judged', (tester) async {
      await _pump(tester,
          status: TaskStatus.pendingApproval, assignedToId: _sibling);
      expect(find.text('Give the stars ⭐'), findsOneWidget);
      expect(find.text('Send back'), findsOneWidget);
    });

    testWidgets('I did offers me nothing — no self-approval', (tester) async {
      await _pump(tester,
          status: TaskStatus.pendingApproval, assignedToId: _me);
      expect(find.text('Give the stars ⭐'), findsNothing);
      expect(find.text('Send back'), findsNothing);
    });
  });

  group('an approved chore', () {
    testWidgets('celebrates and offers nothing', (tester) async {
      await _pump(tester, status: TaskStatus.completed, assignedToId: _me);
      expect(find.text('All done! 🎉'), findsOneWidget);
      expect(find.text('Give it back'), findsNothing);
      expect(find.text("I've done it!"), findsNothing);
    });
  });
}
