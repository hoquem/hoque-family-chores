// Whether now is a good moment to ask for a store rating.
//
// The rule (see the in-app-review feature brief): only ask a parent or
// guardian, only after they have had a few good moments in the app, only
// once the install is a few days old, and never more than a handful of times
// total with a long cooldown between asks. Every threshold is a boundary a
// real user will sit on, so each is tested on both sides.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/review_prompt_gate.dart';

final _installedAt = DateTime(2026, 1, 1);

ReviewPromptHistory _history({
  DateTime? firstSeenAt,
  int positiveMomentCount = kReviewPromptMinPositiveMoments,
  int timesAsked = 0,
  DateTime? lastAskedAt,
}) => ReviewPromptHistory(
  firstSeenAt: firstSeenAt ?? _installedAt,
  positiveMomentCount: positiveMomentCount,
  timesAsked: timesAsked,
  lastAskedAt: lastAskedAt,
);

void main() {
  group('a parent or guardian who qualifies on every count', () {
    test('parent is prompted', () {
      final now = _installedAt.add(const Duration(days: 3));
      expect(
        shouldPromptForReview(
          history: _history(),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isTrue,
      );
    });

    test(
      'guardian is prompted too — the role check is "admin", not "parent"',
      () {
        final now = _installedAt.add(const Duration(days: 3));
        expect(
          shouldPromptForReview(
            history: _history(),
            viewerRole: UserRole.guardian,
            now: now,
          ),
          isTrue,
        );
      },
    );
  });

  group('children are never prompted', () {
    test('a child who otherwise qualifies is refused', () {
      final now = _installedAt.add(const Duration(days: 30));
      expect(
        shouldPromptForReview(
          history: _history(),
          viewerRole: UserRole.child,
          now: now,
        ),
        isFalse,
      );
    });

    test(
      'the unknown-role fallback is refused too, not treated as an adult',
      () {
        final now = _installedAt.add(const Duration(days: 30));
        expect(
          shouldPromptForReview(
            history: _history(),
            viewerRole: UserRole.other,
            now: now,
          ),
          isFalse,
        );
      },
    );
  });

  group('the positive-moment threshold', () {
    test('fewer than 3 moments refuses', () {
      final now = _installedAt.add(const Duration(days: 3));
      expect(
        shouldPromptForReview(
          history: _history(positiveMomentCount: 2),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isFalse,
      );
    });

    test('exactly 3 moments is enough', () {
      final now = _installedAt.add(const Duration(days: 3));
      expect(
        shouldPromptForReview(
          history: _history(positiveMomentCount: 3),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('the 3-day install age', () {
    test('firstSeenAt not yet recorded refuses — too soon to say', () {
      const history = ReviewPromptHistory(
        firstSeenAt: null,
        positiveMomentCount: kReviewPromptMinPositiveMoments,
      );
      expect(
        shouldPromptForReview(
          history: history,
          viewerRole: UserRole.parent,
          now: DateTime(2026, 6, 1),
        ),
        isFalse,
      );
    });

    test('just under 3 days since first seen refuses', () {
      final now = _installedAt.add(
        const Duration(days: 3) - const Duration(seconds: 1),
      );
      expect(
        shouldPromptForReview(
          history: _history(),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isFalse,
      );
    });

    test('exactly 3 days since first seen is enough', () {
      final now = _installedAt.add(const Duration(days: 3));
      expect(
        shouldPromptForReview(
          history: _history(),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('the 90-day cooldown since the last ask', () {
    test(
      'never having asked before does not block an otherwise-eligible ask',
      () {
        final now = _installedAt.add(const Duration(days: 3));
        expect(
          shouldPromptForReview(
            history: _history(lastAskedAt: null),
            viewerRole: UserRole.parent,
            now: now,
          ),
          isTrue,
        );
      },
    );

    test('89 days since the last ask refuses', () {
      final lastAskedAt = _installedAt.add(const Duration(days: 10));
      final now = lastAskedAt.add(const Duration(days: 89));
      expect(
        shouldPromptForReview(
          history: _history(lastAskedAt: lastAskedAt),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isFalse,
      );
    });

    test('exactly 90 days since the last ask is enough', () {
      final lastAskedAt = _installedAt.add(const Duration(days: 10));
      final now = lastAskedAt.add(const Duration(days: 90));
      expect(
        shouldPromptForReview(
          history: _history(lastAskedAt: lastAskedAt),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('the lifetime cap of 3 asks', () {
    test('having asked 3 times already refuses regardless of cooldown', () {
      final now = _installedAt.add(const Duration(days: 400));
      expect(
        shouldPromptForReview(
          history: _history(timesAsked: 3, lastAskedAt: _installedAt),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isFalse,
      );
    });

    test('having asked only twice still allows a third', () {
      final lastAskedAt = _installedAt.add(const Duration(days: 10));
      final now = lastAskedAt.add(const Duration(days: 90));
      expect(
        shouldPromptForReview(
          history: _history(timesAsked: 2, lastAskedAt: lastAskedAt),
          viewerRole: UserRole.parent,
          now: now,
        ),
        isTrue,
      );
    });
  });
}
