import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/logger.dart';

part 'help_hint_notifier.g.dart';

/// Whether the user has ever opened a help sheet.
///
/// Drives a one-time pulse on the `?` button so first-timers notice it. Once
/// they open help anywhere, the pulse never returns.
///
/// Defaults to `true` (no pulse) and corrects to the stored value on load, so a
/// returning user who has already seen it never flickers a pulse; only a genuine
/// first-timer (stored value false/absent) starts pulsing.
@riverpod
class HelpHintSeen extends _$HelpHintSeen {
  static const _key = 'help_hint_seen';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    // Fire-and-forget from build(): swallowing would hide a real prefs failure,
    // so log it — but the pulse is only cosmetic, so degrade to "seen" (no dot)
    // rather than throw an unhandled async error that would take out startup.
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_key) ?? false;
    } catch (e) {
      AppLogger().w('[HelpHint] could not read the seen flag: $e');
    }
  }

  Future<void> markSeen() async {
    if (state) return;
    state = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      AppLogger().w('[HelpHint] could not persist the seen flag: $e');
    }
  }
}
