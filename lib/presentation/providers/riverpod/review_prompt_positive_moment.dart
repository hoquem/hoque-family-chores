import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../di/riverpod_container.dart';
import '../../../utils/logger.dart';
import 'auth_notifier.dart';
import 'review_prompt_pending_signal.dart';

/// Records a chore approval as a review-prompt positive moment for whoever
/// is signed in.
///
/// Call this once, right after an approve use case succeeds — see
/// `TaskListNotifier.approveTask` (the path `task_details_screen.dart`,
/// `add_task_screen.dart` and `task_list_tile.dart` all call), the one place
/// an approval can happen. (`PendingApprovalsNotifier.approveTask` looks
/// like a second one but is unreachable dead code — nothing in `lib/` calls
/// it — so it does not call this and is not exercised by these tests.)
///
/// A non-admin [UserRole] (a child — approving a sibling's chore is normal
/// under this app's trust model, or the unknown-role fallback) returns
/// before anything is read or written. This is not just an optimisation:
/// [ReviewPromptService.onPositiveMoment] already refuses a non-admin role
/// internally, but it does so *after* this function would otherwise have
/// marked [ReviewPromptPendingSignal] — which would schedule a real (if
/// harmless) check in `CelebrationListener` for a moment that was never
/// actually recorded. Checking here keeps a child's approval from touching
/// either side effect at all.
///
/// Always calls [ReviewPromptService.onPositiveMoment] with
/// `canShowSheetNow: false` — an approval happens inside a notifier with no
/// view into whether a dialog is open or the screen is mid-navigation-pop
/// (the task-details screen pops itself right after a successful approve),
/// so there is no safe moment here to show a system dialog over that. The
/// moment still counts toward the gate, and this also marks
/// [ReviewPromptPendingSignal] — "a moment was recorded with nowhere safe to
/// offer the sheet" — so `CelebrationListener` checks again the next time it
/// finds a genuinely idle, undialogued, non-navigating moment. Without that
/// signal, a parent who mostly approves and rarely earns stars or claims a
/// treat personally would have their approvals counted forever without ever
/// actually being asked.
///
/// Awaited by its caller (`TaskListNotifier.approveTask` is already `async`
/// and already awaited by its own callers, so this adds one local-storage
/// write's worth of latency — negligible next to the network round trip the
/// approval itself just made — and it means the moment is durably recorded
/// before `approveTask` returns rather than racing it as a fire-and-forget
/// call; see the comment at that call site on reading everything from [ref]
/// before an await near a `ref.invalidateSelf()`).
///
/// Never throws: reading the signed-in user or reaching the service can fail
/// for reasons that have nothing to do with the approval that just
/// succeeded (a cold-started auth provider, for one), and an approval that
/// already committed must not be turned into a visible error over a
/// review-prompt side effect. Failures are logged and swallowed.
Future<void> recordApprovalPositiveMoment(Ref ref) async {
  try {
    final viewerRole = ref.read(authNotifierProvider).user?.role;
    if (viewerRole == null || !viewerRole.isAdmin) return;
    // Read before the await below, not after — invalidateSelf() runs just
    // before this is called (see TaskListNotifier.approveTask), and every
    // provider this needs is grabbed here, before the first await, so none
    // of it depends on `ref` still being fully "current" afterward.
    final pendingSignal = ref.read(reviewPromptPendingSignalProvider.notifier);
    await ref
        .read(reviewPromptServiceProvider)
        .onPositiveMoment(viewerRole: viewerRole, canShowSheetNow: false);
    pendingSignal.markPending();
  } catch (e, stackTrace) {
    AppLogger().e(
      '[ReviewPrompt] failed to record an approval as a positive moment',
      error: e,
      stackTrace: stackTrace,
    );
  }
}
