// Proves CelebrationListener's deferred-offer mechanism: a review-prompt
// moment recorded with nowhere safe to show a sheet (an approval — see
// review_prompt_positive_moment.dart) marks ReviewPromptPendingSignal, and
// CelebrationListener is the idle point that later evaluates it — but only
// once nothing is covering the screen: no dialog, no pushed route on top,
// and only once the gate itself agrees.
import 'dart:async';

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
import 'package:hoque_family_chores/presentation/motion/celebration_listener.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/review_prompt_pending_signal.dart';
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
final _eligibleNow = _installedAt.add(const Duration(days: 3));

User _parent() => User(
  id: UserId('viewer_1'),
  name: 'Viewer',
  familyId: _familyId,
  role: UserRole.parent,
  points: Points(50),
  joinedAt: _installedAt,
  updatedAt: _installedAt,
);

/// [positiveMomentCount] defaults to a gate-clearing 3; pass a lower value
/// to test the gate's own refusal through this path.
ProviderContainer _containerFor({
  required _MockReviewRequester reviewRequester,
  int positiveMomentCount = 3,
}) {
  SharedPreferences.setMockInitialValues({
    'review_prompt_first_seen_at': _installedAt.millisecondsSinceEpoch,
    'review_prompt_positive_moment_count': positiveMomentCount,
  });
  return ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(AuthState(user: _parent())),
      ),
      reviewRequesterProvider.overrideWith((ref) => reviewRequester),
      reviewPromptServiceProvider.overrideWith(
        (ref) => ReviewPromptService(
          stateService: ReviewPromptStateService(),
          reviewRequester: ref.watch(reviewRequesterProvider),
          clock: () => _eligibleNow,
        ),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'a pending signal is not offered while a dialog is open, and is offered once it closes',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => true);
      when(() => requester.requestReview()).thenAnswer((_) async {});
      final container = _containerFor(reviewRequester: requester);
      addTearDown(container.dispose);

      late BuildContext homeContext;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: appLightTheme,
            home: Scaffold(
              body: CelebrationListener(
                child: Builder(
                  builder: (context) {
                    homeContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A dialog is already open when the approval's moment is recorded.
      unawaited(
        showDialog<void>(
          context: homeContext,
          builder: (_) => const AlertDialog(title: Text('Confirm')),
        ),
      );
      await tester.pumpAndSettle();

      container.read(reviewPromptPendingSignalProvider.notifier).markPending();
      // Past the 300ms settle delay, proving nothing fires while the dialog
      // is still up — not just that nothing fires yet.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      verifyNever(() => requester.isAvailable());

      // Close the dialog — CelebrationListener's route becomes current
      // again, which should schedule the deferred check. pumpAndSettle
      // alone only settles the dialog's own close transition; the extra
      // pump crosses the 300ms settle delay measured from that point.
      Navigator.of(homeContext).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => requester.isAvailable()).called(1);
      verify(() => requester.requestReview()).called(1);
      expect(container.read(reviewPromptPendingSignalProvider), isFalse);
    },
  );

  testWidgets(
    'a pending signal is not offered while another screen is pushed on top, and is offered after popping back',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => true);
      when(() => requester.requestReview()).thenAnswer((_) async {});
      final container = _containerFor(reviewRequester: requester);
      addTearDown(container.dispose);

      late BuildContext homeContext;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: appLightTheme,
            home: Scaffold(
              body: CelebrationListener(
                child: Builder(
                  builder: (context) {
                    homeContext = context;
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      Navigator.of(homeContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Chore details')),
        ),
      );
      await tester.pumpAndSettle();

      container.read(reviewPromptPendingSignalProvider.notifier).markPending();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      verifyNever(() => requester.isAvailable());

      Navigator.of(homeContext).pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => requester.isAvailable()).called(1);
      verify(() => requester.requestReview()).called(1);
    },
  );

  testWidgets(
    'a pending signal the gate refuses is checked but never offered',
    (tester) async {
      final requester = _MockReviewRequester();
      when(() => requester.isAvailable()).thenAnswer((_) async => true);
      when(() => requester.requestReview()).thenAnswer((_) async {});
      // Only 1 positive moment on record — the gate wants at least 3.
      final container = _containerFor(
        reviewRequester: requester,
        positiveMomentCount: 1,
      );
      addTearDown(container.dispose);

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
      await tester.pump();

      container.read(reviewPromptPendingSignalProvider.notifier).markPending();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => requester.isAvailable());
      verifyNever(() => requester.requestReview());
      // The signal is still cleared — a refused gate is a real answer, not
      // a reason to keep re-checking every frame.
      expect(container.read(reviewPromptPendingSignalProvider), isFalse);
    },
  );
}
