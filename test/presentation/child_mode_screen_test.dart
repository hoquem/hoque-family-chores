import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Right, Unit, unit;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/data/services/review_prompt_service.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/usecases/reward/claim_reward_usecase.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_overlay.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/rewards_notifier.dart';
import 'package:hoque_family_chores/presentation/screens/child_mode_screen.dart';
import 'package:hoque_family_chores/presentation/screens/task_details_screen.dart';
import 'package:hoque_family_chores/presentation/sound/sound_player.dart';
import 'package:hoque_family_chores/presentation/sound/sound_service.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';
import '../utils/task_factory.dart';

final _familyId = FamilyId('family_1');

User _kid({bool managed = true}) => User(
      id: UserId('kid'),
      name: 'Amira',
      familyId: _familyId,
      role: UserRole.child,
      points: Points(12),
      joinedAt: DateTime(2026),
      updatedAt: DateTime(2026),
      isManaged: managed,
    );

/// Serves a fixed task list and records who completes / claims, so tests stay
/// off Firebase and can assert the actions act as the child.
class _RecordingTaskRepository extends MockTaskRepository {
  _RecordingTaskRepository(this.seed);

  final List<Task> seed;
  final claims = <(TaskId, UserId)>[];
  final completions = <TaskId>[];

  @override
  Future<List<Task>> getTasksForFamily(FamilyId familyId) async => seed;

  @override
  Stream<List<Task>> streamTasks(FamilyId familyId) => Stream.value(seed);

  @override
  Future<Task?> getTask(FamilyId familyId, TaskId taskId) async =>
      seed.where((t) => t.id == taskId).firstOrNull;

  @override
  Future<void> claimTask(FamilyId familyId, TaskId taskId, UserId userId) async {
    claims.add((taskId, userId));
  }

  @override
  Future<void> completeTask(FamilyId familyId, TaskId taskId) async {
    completions.add(taskId);
  }
}

class _NoAnalytics extends Analytics {
  @override
  Future<void> log(
    AnalyticsEventName name, {
    required String userId,
    String? familyId,
    Map<String, Object?> params = const {},
  }) async {}
}

class _CountingSoundPlayer implements SoundPlayer {
  final played = <String>[];

  @override
  Future<void> play(String asset) async => played.add(asset);
}

final _treat = Reward(
  id: 'park',
  familyId: _familyId,
  title: 'Park trip',
  cost: Points(5),
  timeframe: RewardTimeframe.openEnded,
  createdBy: UserId('mum'),
  createdAt: DateTime(2026),
);

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

final _mum = User(
  id: UserId('mum'),
  name: 'Mum',
  familyId: _familyId,
  role: UserRole.parent,
  points: Points(0),
  joinedAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Records the review-prompt hooks a celebration reaches.
class _RecordingReviewPrompt implements ReviewPromptService {
  final moments = <UserRole>[];
  final offers = <UserRole>[];

  @override
  Future<void> onPositiveMoment({
    required UserRole viewerRole,
    bool canShowSheetNow = true,
  }) async =>
      moments.add(viewerRole);

  @override
  Future<void> offerIfDue(UserRole viewerRole) async => offers.add(viewerRole);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ClaimSucceeds implements ClaimRewardUseCase {
  @override
  Future<Either<Failure, Unit>> call({
    required Reward reward,
    UserId? forMemberId,
  }) async =>
      const Right(unit);
}

Future<_RecordingTaskRepository> _pump(
  WidgetTester tester, {
  required Stream<User?> kid,
  required List<Task> tasks,
  _CountingSoundPlayer? sound,
  _RecordingReviewPrompt? review,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = _RecordingTaskRepository(tasks);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      // ChildModeScreen reads the signed-in parent for analytics, which
      // builds AuthNotifier; keep it off real Firebase.
      authRepositoryProvider.overrideWith((_) => MockAuthRepository()),
      userRepositoryProvider.overrideWith((_) => MockUserRepository()),
      taskRepositoryProvider.overrideWith((_) => repo),
      analyticsProvider.overrideWithValue(_NoAnalytics()),
      soundPlayerProvider.overrideWithValue(sound ?? _CountingSoundPlayer()),
      memberProfileProvider(UserId('kid')).overrideWith((_) => kid),
      familyRewardsProvider(_familyId).overrideWith((_) => Stream.value([_treat])),
      outstandingClaimsProvider(_familyId, UserId('kid'))
          .overrideWith((_) => Stream.value(<Redemption>[])),
      claimRewardUseCaseProvider.overrideWith((_) => _ClaimSucceeds()),
      // A parent is signed in, as on the real shared phone.
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier(AuthState(user: _mum))),
      reviewPromptServiceProvider.overrideWith((_) => review ?? _RecordingReviewPrompt()),
    ],
    child: MaterialApp(
      theme: appLightTheme,
      // The parent's screen celebrates too, as MainScreen does: the child
      // view must not double-play with it.
      home: Builder(
        builder: (context) => Scaffold(
          body: CelebrationListener(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChildModeScreen(childId: UserId('kid'), parentName: 'Mum'),
              )),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('shows only the child\'s chores and the up-for-grabs ones', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
      testTask(id: 'b', title: 'Mum chore', status: TaskStatus.assigned, assignedTo: 'mum'),
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);

    expect(find.text('Amira'), findsOneWidget);
    expect(find.text('Tidy room'), findsOneWidget);
    expect(find.text('Feed cat'), findsOneWidget);
    expect(find.text('Mum chore'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Take'), findsOneWidget);
  });

  testWidgets('Done completes the chore as the child', (tester) async {
    final repo = await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
    ]);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    // The use case only completes when assignedToId == the acting user, so a
    // completion proves the child (not the parent) was the actor.
    expect(repo.completions, [TaskId('a')]);
  });

  testWidgets('Take claims the chore for the child', (tester) async {
    final repo = await _pump(tester, kid: Stream.value(_kid()), tasks: [
      testTask(id: 'c', title: 'Feed cat', status: TaskStatus.available),
    ]);
    await tester.tap(find.text('Take'));
    await tester.pumpAndSettle();
    expect(repo.claims, [(TaskId('c'), UserId('kid'))]);
  });

  testWidgets('Back returns to the parent', (tester) async {
    await _pump(tester, kid: Stream.value(_kid()), tasks: const []);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself once the child is linked to their own phone', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: const []);
    expect(find.text('Amira'), findsOneWidget);

    kid.add(_kid(managed: false));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself when the child is removed', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: const []);

    kid.add(null);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closes itself if the child is already not managed on open', (tester) async {
    await _pump(tester, kid: Stream.value(_kid(managed: false)), tasks: const []);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a profile load error shows the message and a way back', (tester) async {
    await _pump(tester, kid: Stream.error(Exception('boom')), tasks: const []);
    expect(find.textContaining('boom'), findsOneWidget);
    await tester.tap(find.text('Back to Mum'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('closing while chore details is open leaves the parent on top', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: [
      testTask(id: 'a', title: 'Tidy room', status: TaskStatus.assigned, assignedTo: 'kid'),
    ]);
    await tester.tap(find.text('Tidy room'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsScreen), findsOneWidget);

    kid.add(_kid(managed: false));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.byType(ChildModeScreen), findsNothing);
    expect(find.byType(TaskDetailsScreen), findsNothing);
  });

  testWidgets('a later stream error shows the error state', (tester) async {
    final kid = StreamController<User?>();
    addTearDown(kid.close);
    kid.add(_kid());
    await _pump(tester, kid: kid.stream, tasks: const []);
    kid.addError(Exception('lost'));
    await tester.pumpAndSettle();
    expect(find.textContaining('lost'), findsOneWidget);
    expect(find.text('Back to Mum'), findsOneWidget);
  });

  group('celebrations play in the child view, once', () {
    Finder inChildView(Finder f) =>
        find.descendant(of: find.byType(ChildModeScreen), matching: f);

    testWidgets('claiming a treat celebrates where the child can see it',
        (tester) async {
      final sound = _CountingSoundPlayer();
      await _pump(tester, kid: Stream.value(_kid()), tasks: const [], sound: sound);
      await tester.tap(find.text('Treats'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(inChildView(find.byType(CelebrationOverlayView)), findsOneWidget);
      expect(find.byType(CelebrationOverlayView), findsOneWidget,
          reason: "the parent's screen underneath must not play it too");

      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(sound.played, hasLength(1), reason: 'one sound, not one per screen');
      expect(find.byType(CelebrationOverlayView), findsNothing);
    });

    testWidgets("the child's celebration never asks the parent for a review",
        (tester) async {
      final review = _RecordingReviewPrompt();
      await _pump(tester, kid: Stream.value(_kid()), tasks: const [], review: review);
      await tester.tap(find.text('Treats'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      expect(find.byType(CelebrationOverlayView), findsNothing,
          reason: 'the celebration has finished');
      expect(review.moments, isEmpty,
          reason: 'the child is holding the phone, not the signed-in parent');
      expect(review.offers, isEmpty);
    });

    testWidgets('two queued celebrations both play, one after the other',
        (tester) async {
      final sound = _CountingSoundPlayer();
      await _pump(tester, kid: Stream.value(_kid()), tasks: const [], sound: sound);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(ChildModeScreen)));

      container.read(celebrationQueueProvider.notifier)
        ..celebrate(const StarsAwarded(10))
        ..celebrate(const StreakMilestone(3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(inChildView(find.textContaining('+10')), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 100));
      expect(inChildView(find.textContaining('3-day streak')), findsOneWidget);

      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(container.read(celebrationQueueProvider), isEmpty);
      expect(sound.played, hasLength(2));
    });
  });
}
