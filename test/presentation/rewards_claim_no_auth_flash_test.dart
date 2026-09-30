// Regression test: claiming (or settling) a reward used to call
// `ref.invalidate(authNotifierProvider)`. AuthNotifier is `@riverpod`
// (autoDispose), so invalidate() disposes and rebuilds it; the new build()
// synchronously returns `AuthState(status: authenticated)` with `user: null`
// until the Firestore profile stream's first snapshot lands (10-40ms later).
// FamilyGate shows the splash screen whenever `authState.user == null`, so
// every claim/settle briefly swapped the whole MainScreen subtree (including
// CelebrationListener) for the splash and remounted it -- a visible flash.
//
// The fix removes the invalidate: AuthNotifier already streams the user's
// Firestore profile document, and every points change (claim/settle happens
// entirely server-side, in a Cloud Function) arrives through that live
// stream on its own, so nothing needs to force a rebuild.
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/core/error/failures.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/redemption.dart';
import 'package:hoque_family_chores/domain/entities/reward.dart';
import 'package:hoque_family_chores/domain/usecases/reward/claim_reward_usecase.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/main.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/rewards_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

import '../mocks/mock_auth_repository.dart';
import '../mocks/mock_family_repository.dart';
import '../mocks/mock_notification_repository.dart';
import '../mocks/mock_task_repository.dart';
import '../mocks/mock_user_repository.dart';

const _uid = 'mock_google_uid';
final _familyId = FamilyId('family_1');

final _testReward = Reward(
  id: 'reward_1',
  familyId: _familyId,
  title: 'Movie night',
  cost: Points(5),
  timeframe: RewardTimeframe.openEnded,
  createdBy: UserId('parent_1'),
  createdAt: DateTime(2026, 7, 20),
);

/// Claims by handing stars back through the same [MockUserRepository]
/// `streamUserProfile` is watching, standing in for the Cloud Function that
/// owns `points` server-side and writes it straight to Firestore.
class _MockClaimRewardUseCase implements ClaimRewardUseCase {
  _MockClaimRewardUseCase(this._users);
  final MockUserRepository _users;

  @override
  Future<Either<Failure, Unit>> call({required Reward reward}) async {
    await _users.subtractPoints(UserId(_uid), reward.cost);
    return const Right(unit);
  }
}

/// Signs a parent into `family_1` with [points] to spend, then pumps
/// [FamilyGate] (not MainScreen directly), so a transient `user == null`
/// really does swap in the splash screen the way it does in the app.
///
/// [auth] and [users] are handed in (rather than built inline) and always
/// returned as the *same* instance from the override: in production
/// `authRepositoryProvider` wraps `FirebaseAuth.instance`, a singleton that
/// survives a provider rebuild untouched. A fresh mock per override would
/// silently lose the signed-in session on every `invalidate`, which is not
/// the bug under test.
Future<ProviderContainer> _pumpSignedIn(
  WidgetTester tester,
  MockAuthRepository auth,
  MockUserRepository users, {
  required int points,
  required List<Override> rewardOverrides,
}) async {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWith((_) => auth),
      userRepositoryProvider.overrideWith((_) => users),
      familyRepositoryProvider.overrideWith((_) => MockFamilyRepository()),
      taskRepositoryProvider.overrideWith((_) => MockTaskRepository()),
      notificationRepositoryProvider.overrideWith(
        (_) => MockNotificationRepository(),
      ),
      familyRewardsProvider(
        _familyId,
      ).overrideWith((ref) => Stream.value([_testReward])),
      outstandingClaimsProvider(
        _familyId,
        UserId(_uid),
      ).overrideWith((ref) => Future.value(<Redemption>[])),
      ...rewardOverrides,
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: appLightTheme, home: const FamilyGate()),
    ),
  );

  await tester.runAsync(() async {
    await container.read(authNotifierProvider.notifier).signInWithGoogle();
    final profile = await users.getUserProfile(UserId(_uid));
    await users.updateUserProfile(
      profile!.copyWith(familyId: _familyId, points: Points(points)),
    );
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));

  return container;
}

void main() {
  testWidgets(
    'claiming a reward does not null the user or tear down MainScreen',
    (tester) async {
      final auth = MockAuthRepository();
      final users = MockUserRepository();
      final container = await _pumpSignedIn(
        tester,
        auth,
        users,
        points: 50,
        rewardOverrides: [
          claimRewardUseCaseProvider.overrideWith(
            (_) => _MockClaimRewardUseCase(users),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Watch every AuthState emitted from here on -- the real assertion. A
      // widget-tree check alone can miss a null-user frame that never actually
      // painted; this catches it regardless of pump granularity.
      final authStates = <AuthState>[];
      final sub = container.listen(
        authNotifierProvider,
        (_, next) => authStates.add(next),
      );
      addTearDown(sub.close);

      // Switch to the Treats tab.
      await tester.tap(find.text('Treats').last);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(CelebrationListener), findsOneWidget);
      final celebrationListenerState = tester.state(
        find.byType(CelebrationListener),
      );

      await tester.tap(find.text('5 ⭐'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        authStates.any((s) => s.user == null),
        isFalse,
        reason:
            'claiming a reward must not transiently null the signed-in '
            'user -- that is what shows the splash screen',
      );
      expect(
        find.byType(CelebrationListener),
        findsOneWidget,
        reason: 'MainScreen must not have been torn down',
      );
      expect(
        tester.state(find.byType(CelebrationListener)),
        same(celebrationListenerState),
        reason:
            'CelebrationListener must not have been disposed and '
            'remounted -- that is the visible flash',
      );
      expect(find.textContaining('Connecting'), findsNothing);
    },
  );

  testWidgets('the star balance still updates after a claim', (tester) async {
    final auth = MockAuthRepository();
    final users = MockUserRepository();
    final container = await _pumpSignedIn(
      tester,
      auth,
      users,
      points: 50,
      rewardOverrides: [
        claimRewardUseCaseProvider.overrideWith(
          (_) => _MockClaimRewardUseCase(users),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.tap(find.text('Treats').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('50 ⭐'), findsOneWidget);

    await tester.tap(find.text('5 ⭐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    // Re-select the Treats tab: it's a fixed-price bug-severity guard, not
    // part of the assertion -- when the flash tears down MainScreen it also
    // takes bottomNavIndexNotifierProvider with it (autoDispose, last
    // listener gone), so the tab silently pops back to Home. Tapping the
    // already-selected tab post-fix is a harmless no-op.
    await tester.tap(find.text('Treats').last);
    await tester.pump(const Duration(milliseconds: 300));

    // The claim use case spent stars purely by writing through the profile
    // repository (standing in for the server-side Cloud Function); the
    // balance shown must still follow, via the live profile stream alone.
    expect(find.text('45 ⭐'), findsOneWidget);
  });
}
