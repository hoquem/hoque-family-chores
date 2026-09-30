import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/value_objects/family_id.dart';
import '../../utils/logger.dart';

/// Reads and writes when the Home "Invite your family" card was dismissed,
/// per family, in [SharedPreferences].
///
/// Per family, not global: a parent in one family dismissing the card must
/// never hide it for a different family signed into the same device (a
/// shared tablet, say). The decision itself is `shouldShowInviteCard`'s job,
/// not this one. Storage failures are logged and degrade gracefully (treated
/// as "never dismissed") rather than thrown, the same tradeoff
/// `ReviewPromptStateService` makes for its own on-device-only preference:
/// losing a dismissal is never worth crashing Home over.
class InviteCardDismissalService {
  static const _prefix = 'invite_card_dismissed_at_';

  final _logger = AppLogger();

  /// When the card was last dismissed for [familyId], or null if never.
  Future<DateTime?> dismissedAt(FamilyId familyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_key(familyId));
      return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (e, stackTrace) {
      _logger.e(
        '[InviteCard] could not load the dismissal for $familyId',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Records that the card was dismissed for [familyId] at [at].
  Future<void> dismiss(FamilyId familyId, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key(familyId), at.millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      _logger.e(
        '[InviteCard] could not persist the dismissal for $familyId',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  String _key(FamilyId familyId) => '$_prefix${familyId.value}';
}
