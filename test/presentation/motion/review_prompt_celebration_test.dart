// Proves the review-prompt hook wired into CelebrationListener: a payoff
// celebration (stars awarded, a treat claimed) that finishes playing should
// reach ReviewPromptService.onPositiveMoment for a parent whose counters
// clear the gate in review_prompt_gate.dart, and should not for anyone the
// gate refuses. The gate itself is unit-tested in
// test/domain/services/review_prompt_gate_test.dart; this test is about the
// wiring — that the celebration path calls the review service when (and only
// when) it should — not the gate's arithmetic, so only one boundary from each
// gate rule is exercised here.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hoque_family_chores/data/services/review_prompt_service.dart';
import 'package:hoque_family_chores/data/services/review_prompt_state_service.dart';
import 'package:hoque_family_chores/data/services/review_requester.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';

class _MockReviewRequester extends Mock implements ReviewRequester {}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

final _familyId = FamilyId('family_1');
final _installedAt = DateTime(2026, 1, 1);
// Three days after install — the earliest moment the 3-day gate allows.
final _eligibleNow = _installedAt.add(const Duration(days: 3));

User _user(UserRole role) => User(
  id: UserId('viewer_1'),
  name: 'Viewer',
  familyId: _familyId,
  role: role,
  points: Points(50),
  joinedAt: _installedAt,
  updatedAt: _installedAt,
);

/// Builds a container wired for the celebration -> review-prompt path, with
/// [reviewRequester] mocked and every other counter read from a fresh,
/// in-memory SharedPreferences seeded with [prefs].
ProviderContainer _containerFor({
  required UserRole role,
  required _MockReviewRequester reviewRequester,
  required Map<String, Object> prefs,
  DateTime? now,
}) {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(AuthState(user: _user(role))),
      ),
      reviewRequesterProvider.overrideWith((ref) => reviewRequester),
      reviewPromptServiceProvider.overrideWith(
        (ref) => ReviewPromptService(
          stateService: ReviewPromptStateService(),
          reviewRequester: ref.watch(reviewRequesterProvider),
          clock: () => now ?? _eligibleNow,
        ),
      ),
    ],
  );
  return container;
}

Future<void> _pumpCelebration(
  WidgetTester tester,
  ProviderContainer container,
  CelebrationKind kind,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: appLightTheme,
        home: const Scaffold(
          body: CelebrationListener(child: SizedBox.expand()),
        ),
      ),
    ),
  );
  container.read(celebrationQueueProvider.notifier).celebrate(kind);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  // Past the overlay's 700ms envelope, plus a settle frame for onDone.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'a parent whose counters clear the gate is asked to review after the celebration',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => true);
      when(() => requester.requestReview()).thenAnswer((_) async {});

      final container = _containerFor(
        role: UserRole.parent,
        reviewRequester: requester,
        // Two moments already banked; this celebration is the third.
        prefs: {
          'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
          'review_prompt_positive_moment_count': 2,
        },
      );
      addTearDown(container.dispose);

      await _pumpCelebration(tester, container, const StarsAwarded(10));

      verify(() => requester.isAvailable()).called(1);
      verify(() => requester.requestReview()).called(1);
    },
  );

  testWidgets('a parent who has not yet had 3 positive moments is not asked', (
    tester,
  ) async {
    final requester = _MockReviewRequester();
    when(() => requester.isAvailable()).thenAnswer((_) async => true);
    when(() => requester.requestReview()).thenAnswer((_) async {});

    final container = _containerFor(
      role: UserRole.parent,
      reviewRequester: requester,
      // No prior moments — this celebration only brings the count to 1.
      prefs: {
        'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
      },
    );
    addTearDown(container.dispose);

    await _pumpCelebration(tester, container, const StarsAwarded(10));

    verifyNever(() => requester.requestReview());
  });

  testWidgets(
    'a child whose counters would otherwise clear the gate is never asked',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => true);
      when(() => requester.requestReview()).thenAnswer((_) async {});

      final container = _containerFor(
        role: UserRole.child,
        reviewRequester: requester,
        prefs: {
          'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
          'review_prompt_positive_moment_count': 2,
        },
      );
      addTearDown(container.dispose);

      await _pumpCelebration(tester, container, const StarsAwarded(10));

      verifyNever(() => requester.isAvailable());
      verifyNever(() => requester.requestReview());
    },
  );

  testWidgets(
    'a qualifying parent is not asked when the platform reports the sheet unavailable',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => false);

      final container = _containerFor(
        role: UserRole.parent,
        reviewRequester: requester,
        prefs: {
          'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
          'review_prompt_positive_moment_count': 2,
        },
      );
      addTearDown(container.dispose);

      await _pumpCelebration(tester, container, const StarsAwarded(10));

      verify(() => requester.isAvailable()).called(1);
      verifyNever(() => requester.requestReview());
    },
  );

  testWidgets('a streak milestone alone never counts as a positive moment', (
    tester,
  ) async {
    final requester = _MockReviewRequester();
    when(() => requester.isAvailable()).thenAnswer((_) async => true);
    when(() => requester.requestReview()).thenAnswer((_) async {});

    final container = _containerFor(
      role: UserRole.parent,
      reviewRequester: requester,
      // Already at the moment threshold via prior rewards; only a streak
      // plays this time, which must not itself trigger a check.
      prefs: {
        'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
        'review_prompt_positive_moment_count': 3,
      },
    );
    addTearDown(container.dispose);

    await _pumpCelebration(tester, container, const StreakMilestone(3));

    verifyNever(() => requester.isAvailable());
    verifyNever(() => requester.requestReview());
  });
}
