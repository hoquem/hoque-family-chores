import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/home_stats.dart';
import 'package:hoque_family_chores/domain/value_objects/email.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/bottom_nav_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/home_screen.dart';
import 'package:hoque_family_chores/presentation/screens/main_screen.dart';
import 'package:hoque_family_chores/presentation/screens/member_detail_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/presentation/widgets/home/celebration_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/greeting_header.dart';
import 'package:hoque_family_chores/presentation/widgets/home/leaderboard_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/progress_card.dart';
import 'package:hoque_family_chores/presentation/widgets/home/today_missions_card.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _me = UserId(_uid);
final _familyId = FamilyId('family_1');

/// Phone width, generous height: Home is a long scroll and these tests tap
/// cards below the fold. The fallback font in `flutter_test` measures wider
/// than the real one, so the height buys room the device would not need.
const _phone = Size(430, 2000);

Task _task(
  String id, {
  String? title,
  TaskStatus status = TaskStatus.assigned,
  UserId? assignedTo,
  DateTime? completedAt,
  int points = 10,
}) =>
    Task(
      id: TaskId(id),
      title: title ?? 'Task $id',
      description: '',
      status: status,
      difficulty: TaskDifficulty.easy,
      dueDate: DateTime.now(),
      assignedToId: assignedTo ?? _me,
      createdById: UserId('user_1'),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      completedAt: completedAt,
      approvedAt:
          status == TaskStatus.completed ? (completedAt ?? DateTime.now()) : null,
      points: Points(points),
      tags: const [],
      familyId: _familyId,
    );

User _member(String id, String name) => User(
      id: UserId(id),
      name: name,
      // The Email value object rejects underscores, which ids like
      // mock_google_uid contain — so key the address off the name.
      email: Email('${name.split(' ').first.toLowerCase()}@example.com'),
      familyId: _familyId,
      role: UserRole.child,
      points: Points(0),
      joinedAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );

void _sizePhone(WidgetTester tester) {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// Pumps a single card on its own — no providers, no navigation, so these
/// stay fast and prove only that the card reports the tap.
Future<void> _pumpCard(WidgetTester tester, Widget card) async {
  _sizePhone(tester);
  await tester.pumpWidget(
    MaterialApp(theme: appLightTheme, home: Scaffold(body: card)),
  );
  await tester.pump();
}

class _SeededFamilyRepository extends MockFamilyRepository {
  _SeededFamilyRepository(this.members);
  final List<User> members;

  @override
  Future<List<User>> getFamilyMembers(FamilyId familyId) async => members;
}

/// Pumps the real Home screen against mock repositories, so the wiring
/// between card callbacks and navigation is exercised for real.
Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  required List<Task> tasks,
  List<User> extraMembers = const [],
  Widget home = const HomeScreen(),
}) async {
  _sizePhone(tester);

  final users = MockUserRepository();
  final taskRepo = MockTaskRepository();
  for (final task in tasks) {
    taskRepo.addTaskSync(task);
  }

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => _SeededFamilyRepository([
            _member(_uid, 'Maya Hoque'),
            ...extraMembers,
          ])),
      taskRepositoryProvider.overrideWith((_) => taskRepo),
      notificationRepositoryProvider
          .overrideWith((_) => MockNotificationRepository()),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: home),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(_me);
    await users.updateUserProfile(profile!.copyWith(
      name: 'Maya Hoque',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(150),
    ));
  });
  // Auth propagates, the task stream delivers, then the members provider
  // (first watched once tasks have data) resolves.
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }

  return container;
}

void main() {
  group('TodayMissionsCard reports which chore was tapped', () {
    testWidgets('a mission still to do', (tester) async {
      final opened = <Task>[];
      final mission = _task('cat', title: 'Feed the cat');
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
              toDo: [mission], waiting: const [], done: const []),
          onComplete: (_) {},
          onClaim: (_) {},
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.text('Feed the cat'));
      await tester.pump();

      expect(opened, [mission]);
    });

    testWidgets('a mission waiting for approval', (tester) async {
      final opened = <Task>[];
      final mission =
          _task('bin', title: 'Bins out', status: TaskStatus.pendingApproval);
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
              toDo: const [], waiting: [mission], done: const []),
          onComplete: (_) {},
          onClaim: (_) {},
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.text('Bins out'));
      await tester.pump();

      expect(opened, [mission]);
    });

    testWidgets('a mission finished today', (tester) async {
      final opened = <Task>[];
      final mission = _task('bed',
          title: 'Make the bed',
          status: TaskStatus.completed,
          completedAt: DateTime.now());
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
              toDo: const [], waiting: const [], done: [mission]),
          onComplete: (_) {},
          onClaim: (_) {},
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.text('Make the bed'));
      await tester.pump();

      expect(opened, [mission]);
    });

    testWidgets('a chore going spare opens rather than claiming',
        (tester) async {
      final opened = <Task>[];
      final claimed = <Task>[];
      final spare = _task('lawn', title: 'Mow the lawn');
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
            toDo: const [],
            waiting: const [],
            done: const [],
            claimable: [spare],
          ),
          onComplete: (_) {},
          onClaim: claimed.add,
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.text('Mow the lawn'));
      await tester.pump();

      expect(opened, [spare], reason: 'the row body opens the chore');
      expect(claimed, isEmpty, reason: 'only the + button claims it');
    });

    testWidgets("the I've-done-it button completes without opening",
        (tester) async {
      final opened = <Task>[];
      final completed = <Task>[];
      final mission = _task('cat', title: 'Feed the cat');
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
              toDo: [mission], waiting: const [], done: const []),
          onComplete: completed.add,
          onClaim: (_) {},
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.byTooltip("I've done it!"));
      await tester.pump();

      expect(completed, [mission]);
      expect(opened, isEmpty,
          reason: 'the action button must not also open the details screen');
    });

    testWidgets("the I'll-do-it button claims without opening", (tester) async {
      final opened = <Task>[];
      final claimed = <Task>[];
      final spare = _task('lawn', title: 'Mow the lawn');
      await _pumpCard(
        tester,
        TodayMissionsCard(
          missions: TodayMissions(
            toDo: const [],
            waiting: const [],
            done: const [],
            claimable: [spare],
          ),
          onComplete: (_) {},
          onClaim: claimed.add,
          onOpen: opened.add,
        ),
      );

      await tester.tap(find.byTooltip("I'll do it"));
      await tester.pump();

      expect(claimed, [spare]);
      expect(opened, isEmpty);
    });
  });

  testWidgets('LeaderboardCard reports which member was tapped',
      (tester) async {
    final opened = <User>[];
    final zafir = _member('zafir', 'Zafir');
    await _pumpCard(
      tester,
      LeaderboardCard(
        ranking: [
          MemberStars(member: zafir, stars: 60),
          MemberStars(member: _member('priya', 'Priya'), stars: 20),
        ],
        onOpenMember: opened.add,
      ),
    );

    await tester.tap(find.text('Zafir'));
    await tester.pump();

    expect(opened, [zafir]);
  });

  testWidgets('ProgressCard reports a tap', (tester) async {
    var taps = 0;
    await _pumpCard(
      tester,
      ProgressCard(points: 150, streak: 3, onTap: () => taps++),
    );

    await tester.tap(find.byType(ProgressCard));
    await tester.pump();

    expect(taps, 1);
  });

  group('no dead taps', () {
    testWidgets('the celebration card offers no tap target', (tester) async {
      await _pumpCard(tester, const CelebrationCard());
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('the greeting header offers no tap target', (tester) async {
      await _pumpCard(
        tester,
        GreetingHeader(user: _member(_uid, 'Maya Hoque')),
      );
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('Home wires the taps to somewhere real', () {
    testWidgets('tapping a mission opens that chore', (tester) async {
      await _pumpHome(tester, tasks: [_task('cat', title: 'Feed the cat')]);

      await tester.tap(find.text('Feed the cat'));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailsScreen), findsOneWidget);
    });

    testWidgets('tapping a leaderboard row opens that member', (tester) async {
      await _pumpHome(
        tester,
        extraMembers: [_member('zafir', 'Zafir')],
        tasks: [
          _task('z1',
              title: 'Mow the lawn',
              assignedTo: UserId('zafir'),
              status: TaskStatus.completed,
              completedAt: DateTime.now(),
              points: 60),
        ],
      );

      await tester.tap(find.text('Zafir'));
      await tester.pumpAndSettle();

      expect(find.byType(MemberDetailScreen), findsOneWidget);
    });

    testWidgets('tapping the progress card lands on the Treats tab',
        (tester) async {
      // The whole app, not just Home: the nav provider is autoDispose, so it
      // only holds an index while MainScreen is watching it — and arriving on
      // Treats is the thing worth proving anyway.
      final container = await _pumpHome(
        tester,
        home: const MainScreen(),
        tasks: [_task('cat', title: 'Feed the cat')],
      );

      expect(container.read(bottomNavIndexNotifierProvider), 0);

      await tester.tap(find.byType(ProgressCard));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Treats is index 2 in MainScreen: Home, Chores, Treats, Family, You.
      expect(container.read(bottomNavIndexNotifierProvider), 2);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Treats')),
        findsOneWidget,
      );
    });
  });
}
