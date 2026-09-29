import '../../domain/entities/user.dart';
import '../../domain/services/review_prompt_gate.dart';
import '../../utils/logger.dart';
import 'review_prompt_state_service.dart';
import 'review_requester.dart';

/// Turns a payoff moment into, at most, one store-review ask.
///
/// Called from `CelebrationListener` once a celebration has finished playing
/// — see that widget's `onDone` for why that moment, and not the queue's
/// `celebrate()` call, is the hook. [onPositiveMoment] never throws: every
/// failure — storage, or the plugin itself — is logged with [AppLogger] and
/// swallowed, so a review-prompt hiccup can never take a celebration down
/// with it. Callers do not need to await it for that reason, though they may.
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

  /// Records a payoff moment for [viewerRole] and, if [shouldPromptForReview]
  /// agrees and the platform reports [ReviewRequester.isAvailable], requests
  /// the store's native review dialog.
  ///
  /// A non-admin [viewerRole] (a child, or the unknown-role fallback) is
  /// skipped before anything is read or written — a child's session can
  /// never spend the family's lifetime ask budget.
  ///
  /// A [ReviewRequester.requestReview] that throws is logged but **not**
  /// recorded as an ask: the budget is for asks that were actually offered
  /// to the platform, not ones that errored before reaching it, so the next
  /// qualifying moment gets to try again rather than waiting out a 90-day
  /// cooldown for nothing.
  Future<void> onPositiveMoment({required UserRole viewerRole}) async {
    if (!viewerRole.isAdmin) return;
    try {
      final history = await _stateService.recordPositiveMoment();
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
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] failed to process a positive moment',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
