import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a piece of text.
abstract interface class InviteSharer {
  /// :param text: what to share.
  /// :param origin: the tapped control's global rect. Required on iPad, where
  ///     the share sheet is a popover that must point at something.
  /// :returns: false only when the person dismissed the share sheet without
  ///     picking anything — the caller must not log a share or treat it as
  ///     one for that result. True otherwise, including when the platform
  ///     cannot report what happened (`unavailable`, common on Android):
  ///     silence must not turn into an undercount.
  Future<bool> share(String text, {Rect? origin});
}

class SystemInviteSharer implements InviteSharer {
  @override
  Future<bool> share(String text, {Rect? origin}) async {
    final result = await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
    return result.status != ShareResultStatus.dismissed;
  }
}

/// Hand-written rather than generated: build_runner cannot currently run in
/// this repo (the pinned analyzer predates the SDK's dot-shorthand syntax).
final inviteSharerProvider =
    Provider<InviteSharer>((_) => SystemInviteSharer());
