import '../../domain/entities/user.dart';
import '../../domain/services/review_prompt_gate.dart';
import '../../utils/logger.dart';
import 'review_prompt_state_service.dart';
import 'review_requester.dart';

/// Turns a payoff moment into, at most, one store-review ask.
///
/// Two entry points feed it:
///
/// - [onPositiveMoment] — called from `CelebrationListener` once a
///   celebration has finished playing (see that widget's `onDone` for why
///   that moment, and not the queue's `celebrate()` call, is the hook), and
///   from an approval's success path (see
///   `review_prompt_positive_moment.dart`). It always records the moment,
///   and evaluates the gate itself only when [canShowSheetNow].
/// - [offerIfDue] — evaluates the gate against whatever is already
///   recorded, without adding a moment. This is what a deferred offer (an
///   approval, which has no safe moment of its own to show a system dialog)
///   uses once a later, genuinely safe moment arrives — see
///   `ReviewPromptPendingSignal` and `CelebrationListener`.
///
/// Neither throws: every failure — storage, or the plugin itself — is
/// logged with [AppLogger] and swallowed, so a review-prompt hiccup can
/// never take whatever it was called from down with it.
class ReviewPromptService {
  ReviewPromptService({
    required ReviewPromptStateService stateService,
    required ReviewRequester reviewRequester,
    DateTime Function() clock = DateTime.now,
  }) : _stateService = stateService,
       _reviewRequester = reviewRequester,
       _clock = clock;

  final ReviewPromptStateService _stateService;
  final ReviewRequester _reviewRequester;
  final DateTime Function() _clock;
  final _logger = AppLogger();

  /// Records a payoff moment for [viewerRole] and, if [canShowSheetNow],
  /// evaluates the gate and may offer the sheet — see [_evaluateAndOffer].
  ///
  /// The moment is always recorded regardless of [canShowSheetNow] — a
  /// celebration that finishes with another one already queued behind it is
  /// still a real positive moment, it just is not a safe time to interrupt
  /// with a system dialog. [canShowSheetNow] controls only whether the ask
  /// is even considered this time; counting it on every call, not only when
  /// the sheet might show, is what stops back-to-back celebrations from
  /// silently under-counting the audience that already earns the fewest of
  /// them.
  ///
  /// A non-admin [viewerRole] (a child, or the unknown-role fallback) is
  /// skipped before anything is read or written — a child's session can
  /// never spend the family's lifetime ask budget, and never pads the count
  /// either.
  Future<void> onPositiveMoment({
    required UserRole viewerRole,
    bool canShowSheetNow = true,
  }) async {
    if (!viewerRole.isAdmin) return;
    try {
      final history = await _stateService.recordPositiveMoment();
      if (!canShowSheetNow) return;
      await _evaluateAndOffer(history, viewerRole);
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] failed to process a positive moment',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Evaluates the gate against the moments already on record — without
  /// adding one — and offers the sheet if due.
  ///
  /// For a moment that had no safe place to offer the sheet of its own (an
  /// approval, recorded via [onPositiveMoment] with `canShowSheetNow:
  /// false`), the caller marks a pending signal and calls this once it finds
  /// a genuinely idle, undialogued, non-navigating moment — see
  /// `CelebrationListener`.
  Future<void> offerIfDue(UserRole viewerRole) async {
    if (!viewerRole.isAdmin) return;
    try {
      final history = await _stateService.load();
      await _evaluateAndOffer(history, viewerRole);
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] failed to evaluate a deferred offer',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Shared by both entry points: if [shouldPromptForReview] agrees and the
  /// platform reports [ReviewRequester.isAvailable], requests the native
  /// review dialog.
  ///
  /// A [ReviewRequester.requestReview] that throws is logged but **not**
  /// recorded as an ask: the budget is for asks that were actually offered
  /// to the platform, not ones that errored before reaching it, so the next
  /// qualifying moment gets to try again rather than waiting out a 90-day
  /// cooldown for nothing. (The throw propagates to each entry point's own
  /// try/catch, which logs it — this method does not catch it itself.)
  Future<void> _evaluateAndOffer(
    ReviewPromptHistory history,
    UserRole viewerRole,
  ) async {
    final now = _clock();
    if (!shouldPromptForReview(
      history: history,
      viewerRole: viewerRole,
      now: now,
    )) {
      return;
    }
    if (!await _reviewRequester.isAvailable()) return;
    await _reviewRequester.requestReview();
    await _stateService.recordAsked(now);
  }
}
