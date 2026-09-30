import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "A review-prompt moment was recorded with nowhere safe to offer the
/// sheet — check again once somewhere safe turns up."
///
/// Hand-written, not `@riverpod` codegen: it is one bool with two mutators,
/// and generating a whole provider file for that would be the "interface
/// mirrors the implementation" red flag ENGINEERING.md warns about, for no
/// benefit — this also sidesteps a `build_runner` run over unrelated
/// providers for a change this small.
///
/// Set by `recordApprovalPositiveMoment` (see review_prompt_positive_moment.dart)
/// right after an approval records a moment it could not safely offer the
/// sheet for. Watched by `CelebrationListener`, which clears it once it
/// finds a moment that is: no celebration playing, no dialog or other route
/// on top (`ModalRoute.of(context)?.isCurrent`), and calls
/// `ReviewPromptService.offerIfDue` to decide whether that moment is
/// actually good enough to ask.
class ReviewPromptPendingSignal extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marks a check as owed. Idempotent — a second approval before the first
  /// check runs does not need a second signal.
  void markPending() {
    if (!state) state = true;
  }

  /// Clears the signal once a check has run (whether or not it offered the
  /// sheet — a refused gate is a real answer, not a reason to keep asking
  /// every frame).
  void clear() {
    if (state) state = false;
  }
}

final reviewPromptPendingSignalProvider =
    NotifierProvider<ReviewPromptPendingSignal, bool>(
      ReviewPromptPendingSignal.new,
    );
