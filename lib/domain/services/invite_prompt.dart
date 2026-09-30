import '../entities/user.dart';

/// How long a dismissed "Invite your family" card stays hidden before it
/// can resurface, if the family is still solo.
const Duration kInviteCardSnoozeDuration = Duration(days: 7);

/// Whether to show the Home "Invite your family" card.
///
/// All of the following must hold:
///
/// - [viewerRole] is a parent or guardian. Checked with [UserRole.isAdmin],
///   the same test `shouldPromptForReview` uses — not `== UserRole.parent`,
///   so a guardian sees it too. A child cannot act on family membership, and
///   the card's wording assumes an adult decision.
/// - [memberCount] is exactly 1 — the family is solo. A count of 0 means the
///   members list has not loaded yet, not "solo", and refuses rather than
///   risk a flash of the card before the real count arrives. Two or more
///   means a second member already joined: the card has done its job.
/// - [dismissedAt] is null (never dismissed) or at least
///   [kInviteCardSnoozeDuration] in the past — a dismissal is a "not now",
///   not a "never", for a family that is still solo a week later.
///
/// Pure and stateless — [now] is a parameter, not read from a clock, so
/// every boundary above is deterministic to test.
bool shouldShowInviteCard({
  required int memberCount,
  required UserRole viewerRole,
  required DateTime? dismissedAt,
  required DateTime now,
}) {
  if (!viewerRole.isAdmin) return false;
  if (memberCount != 1) return false;

  if (dismissedAt == null) return true;
  return now.difference(dismissedAt) >= kInviteCardSnoozeDuration;
}
