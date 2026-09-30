import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a piece of text.
abstract interface class InviteSharer {
  /// :param text: what to share.
  /// :param origin: the tapped control's global rect. Required on iPad, where
  ///     the share sheet is a popover that must point at something.
  Future<void> share(String text, {Rect? origin});
}

class SystemInviteSharer implements InviteSharer {
  @override
  Future<void> share(String text, {Rect? origin}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
  }
}

/// Hand-written rather than generated: build_runner cannot currently run in
/// this repo (the pinned analyzer predates the SDK's dot-shorthand syntax).
final inviteSharerProvider =
    Provider<InviteSharer>((_) => SystemInviteSharer());
