import 'package:equatable/equatable.dart';
import '../entities/user.dart';

/// How many payoff moments [shouldPromptForReview] wants to see before it
/// will ever say yes.
const int kReviewPromptMinPositiveMoments = 3;

/// How old the install must be before the first ask.
const Duration kReviewPromptMinAgeSinceFirstSeen = Duration(days: 3);

/// How long to wait after an ask before offering another.
const Duration kReviewPromptCooldown = Duration(days: 90);

/// How many times we will ever ask, for the life of the install.
const int kReviewPromptMaxAsks = 3;

/// The counters [shouldPromptForReview] decides from, persisted across
/// launches by `ReviewPromptStateService`.
///
/// Pure data: nothing here reads a clock or `SharedPreferences`.
class ReviewPromptHistory extends Equatable {
  const ReviewPromptHistory({
    required this.firstSeenAt,
    this.positiveMomentCount = 0,
    this.timesAsked = 0,
    this.lastAskedAt,
  });

  /// When this install was first seen. Null only before the app seeds it on
  /// first launch — [shouldPromptForReview] reads a null [firstSeenAt] as
  /// "too soon to say" and refuses.
  final DateTime? firstSeenAt;

  /// How many qualifying celebrations (stars awarded, a treat claimed) have
  /// played since install.
  final int positiveMomentCount;

  /// How many times the store review sheet has been requested, ever.
  final int timesAsked;

  /// When the review sheet was last requested. Null if never.
  final DateTime? lastAskedAt;

  /// Returns a copy with the given fields replaced.
  ReviewPromptHistory copyWith({
    DateTime? firstSeenAt,
    int? positiveMomentCount,
    int? timesAsked,
    DateTime? lastAskedAt,
  }) => ReviewPromptHistory(
    firstSeenAt: firstSeenAt ?? this.firstSeenAt,
    positiveMomentCount: positiveMomentCount ?? this.positiveMomentCount,
    timesAsked: timesAsked ?? this.timesAsked,
    lastAskedAt: lastAskedAt ?? this.lastAskedAt,
  );

  @override
  List<Object?> get props => [
    firstSeenAt,
    positiveMomentCount,
    timesAsked,
    lastAskedAt,
  ];
}

/// Whether now is a good moment to ask [viewerRole] for a store rating.
///
/// All of the following must hold (spec: grow ratings without nagging):
///
/// - [viewerRole] is a parent or guardian. Children join anonymously with no
///   store account to rate from, and a rating prompt is not their decision to
///   make. Checked with [UserRole.isAdmin], the same test [taskActionsFor]
///   uses — not `== UserRole.parent`, so a guardian is asked too.
/// - at least [kReviewPromptMinPositiveMoments] payoff moments have played.
/// - at least [kReviewPromptMinAgeSinceFirstSeen] has passed since
///   [ReviewPromptHistory.firstSeenAt]. A null [ReviewPromptHistory.firstSeenAt]
///   refuses rather than treating "unknown" as "long enough ago".
/// - we have asked fewer than [kReviewPromptMaxAsks] times, ever.
/// - [ReviewPromptHistory.lastAskedAt] is null (never asked) or at least
///   [kReviewPromptCooldown] in the past.
///
/// Pure and stateless — [now] is a parameter, not read from a clock, so
/// every boundary above is deterministic to test.
bool shouldPromptForReview({
  required ReviewPromptHistory history,
  required UserRole viewerRole,
  required DateTime now,
}) {
  if (!viewerRole.isAdmin) return false;

  final firstSeenAt = history.firstSeenAt;
  if (firstSeenAt == null) return false;
  if (now.difference(firstSeenAt) < kReviewPromptMinAgeSinceFirstSeen) {
    return false;
  }

  if (history.positiveMomentCount < kReviewPromptMinPositiveMoments) {
    return false;
  }

  if (history.timesAsked >= kReviewPromptMaxAsks) return false;

  final lastAskedAt = history.lastAskedAt;
  if (lastAskedAt != null &&
      now.difference(lastAskedAt) < kReviewPromptCooldown) {
    return false;
  }

  return true;
}
