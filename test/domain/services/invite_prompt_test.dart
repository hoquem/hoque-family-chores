// Whether to show the Home "Invite your family" card.
//
// The rule: only a parent or guardian sees it (a child cannot act on
// inviting someone), only while the family is solo (one member), and once
// dismissed it stays hidden for a week in case the family is still solo
// when it comes back. Every threshold is a boundary a real user will sit
// on, so each is tested on both sides.
import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/domain/services/invite_prompt.dart';

final _now = DateTime(2026, 6, 1);

void main() {
  group('a solo family, never dismissed', () {
    test('a parent sees the card', () {
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.parent,
          dismissedAt: null,
          now: _now,
        ),
        isTrue,
      );
    });

    test('a guardian sees it too — the role check is "admin", not "parent"',
        () {
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.guardian,
          dismissedAt: null,
          now: _now,
        ),
        isTrue,
      );
    });
  });

  group('children never see it', () {
    test('a child in an otherwise-qualifying solo family is refused', () {
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.child,
          dismissedAt: null,
          now: _now,
        ),
        isFalse,
      );
    });

    test('the unknown-role fallback is refused too, not treated as an admin',
        () {
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.other,
          dismissedAt: null,
          now: _now,
        ),
        isFalse,
      );
    });
  });

  group('member count', () {
    test('a second member hides the card', () {
      expect(
        shouldShowInviteCard(
          memberCount: 2,
          viewerRole: UserRole.parent,
          dismissedAt: null,
          now: _now,
        ),
        isFalse,
      );
    });

    test('a family with no members loaded yet is not "solo", it is unknown',
        () {
      expect(
        shouldShowInviteCard(
          memberCount: 0,
          viewerRole: UserRole.parent,
          dismissedAt: null,
          now: _now,
        ),
        isFalse,
      );
    });
  });

  group('the 7-day dismissal snooze', () {
    test('just under 7 days since dismissal stays hidden', () {
      final dismissedAt =
          _now.subtract(const Duration(days: 7) - const Duration(seconds: 1));
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.parent,
          dismissedAt: dismissedAt,
          now: _now,
        ),
        isFalse,
      );
    });

    test('exactly 7 days since dismissal shows it again', () {
      final dismissedAt = _now.subtract(const Duration(days: 7));
      expect(
        shouldShowInviteCard(
          memberCount: 1,
          viewerRole: UserRole.parent,
          dismissedAt: dismissedAt,
          now: _now,
        ),
        isTrue,
      );
    });
  });
}
