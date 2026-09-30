import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/core/analytics/analytics.dart';
import 'package:hoque_family_chores/data/services/invite_sharer.dart';
import 'package:hoque_family_chores/domain/services/invite_message.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

/// Opens the system share sheet with the family's invite message and logs
/// [AnalyticsEventName.inviteShared] tagged with where the tap happened.
///
/// Shared by every "Share invite" entry point (the Family tab's invite
/// dialog, its labelled quick-share button, the Home solo-family card, and
/// the post-create onboarding step) so the share text, error handling and
/// analytics stay in one place rather than four near-copies of the same
/// eleven lines.
///
/// :param origin: the tapped control's global rect, resolved by the caller
///     before any `await` (a widget can unmount mid-share). Required on
///     iPad, where the share sheet is a popover that must point at
///     something; harmless elsewhere.
/// :param onShared: called after a successful share, before the analytics
///     write. [InviteYourFamilyScreen] uses this to relabel its exit button
///     from "Maybe later" to "Done" so a completed share is never logged as
///     a skip.
Future<void> shareInvite(
  BuildContext context,
  WidgetRef ref, {
  required String inviteCode,
  required String source,
  Rect? origin,
  VoidCallback? onShared,
}) async {
  try {
    await ref
        .read(inviteSharerProvider)
        .share(inviteMessage(inviteCode), origin: origin);
    onShared?.call();
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser != null) {
      ref.read(analyticsProvider).log(
            AnalyticsEventName.inviteShared,
            userId: currentUser.id.value,
            familyId: currentUser.familyId.value,
            params: {'source': source},
          );
    }
  } catch (e) {
    logger.e('shareInvite: sharing the invite failed (source=$source)',
        error: e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open sharing. Use Copy instead."),
      ),
    );
  }
}

/// A "Share invite" button: finds its own on-screen position (for the iPad
/// popover origin) and calls [shareInvite].
class ShareInviteButton extends ConsumerWidget {
  const ShareInviteButton({
    super.key,
    required this.inviteCode,
    required this.source,
    this.label = 'Share invite',
    this.onShared,
  });

  /// The family's invite code, as stored (not the grouped display form).
  final String inviteCode;

  /// Where this button appears, for the `inviteShared` analytics event's
  /// `source` param: `'onboarding'`, `'home_card'`, `'family_tab'` or
  /// `'dialog'`.
  final String source;

  /// The button's visible text.
  final String label;

  /// Called after a successful share.
  final VoidCallback? onShared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (buttonContext) => FilledButton.icon(
        onPressed: () {
          final box = buttonContext.findRenderObject() as RenderBox?;
          final origin =
              box == null ? null : box.localToGlobal(Offset.zero) & box.size;
          shareInvite(
            context,
            ref,
            inviteCode: inviteCode,
            source: source,
            origin: origin,
            onShared: onShared,
          );
        },
        icon: const Icon(Icons.ios_share),
        label: Text(label),
      ),
    );
  }
}
