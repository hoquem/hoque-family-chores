import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/review_prompt_gate.dart';
import '../../utils/logger.dart';

/// Reads and writes [ReviewPromptHistory] in [SharedPreferences].
///
/// This class only loads, seeds and saves counters — the decision itself is
/// [shouldPromptForReview]'s job, not this one. Storage failures are logged
/// and degrade gracefully (an empty/unchanged history) rather than thrown,
/// the same tradeoff `NotificationPreferencesService` and `HelpHintSeen` make
/// for other cosmetic, on-device-only preferences: losing a review ask is
/// never worth crashing a celebration over.
class ReviewPromptStateService {
  static const _prefix = 'review_prompt_';
  static const _firstSeenAtKey = '${_prefix}first_seen_at';
  static const _positiveMomentCountKey = '${_prefix}positive_moment_count';
  static const _timesAskedKey = '${_prefix}times_asked';
  static const _lastAskedAtKey = '${_prefix}last_asked_at';

  final _logger = AppLogger();

  /// Records "now" as [ReviewPromptHistory.firstSeenAt] the first time this
  /// runs for an install; a no-op on every call after.
  ///
  /// Call this once at app startup (see `main.dart`), never from a
  /// celebration — seeding it on the first payoff moment instead of the
  /// first launch would start the 3-day clock late.
  Future<void> ensureFirstSeenSeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_firstSeenAtKey)) return;
      await prefs.setInt(
        _firstSeenAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] could not seed the first-seen date',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// The current counters, as persisted. Falls back to a fresh,
  /// never-seen-anything history on a storage failure.
  Future<ReviewPromptHistory> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return ReviewPromptHistory(
        firstSeenAt: _readDate(prefs, _firstSeenAtKey),
        positiveMomentCount: prefs.getInt(_positiveMomentCountKey) ?? 0,
        timesAsked: prefs.getInt(_timesAskedKey) ?? 0,
        lastAskedAt: _readDate(prefs, _lastAskedAtKey),
      );
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] could not load the ask history',
        error: e,
        stackTrace: stackTrace,
      );
      return const ReviewPromptHistory(firstSeenAt: null);
    }
  }

  /// Records one more payoff moment (stars awarded, a treat claimed) and
  /// returns the updated history for the caller to evaluate.
  Future<ReviewPromptHistory> recordPositiveMoment() async {
    final history = await load();
    final updated = history.copyWith(
      positiveMomentCount: history.positiveMomentCount + 1,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_positiveMomentCountKey, updated.positiveMomentCount);
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] could not persist a positive moment',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return updated;
  }

  /// Records that the store review sheet was requested at [askedAt].
  Future<void> recordAsked(DateTime askedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timesAsked = prefs.getInt(_timesAskedKey) ?? 0;
      await prefs.setInt(_timesAskedKey, timesAsked + 1);
      await prefs.setInt(_lastAskedAtKey, askedAt.millisecondsSinceEpoch);
    } catch (e, stackTrace) {
      _logger.e(
        '[ReviewPrompt] could not persist an ask',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  DateTime? _readDate(SharedPreferences prefs, String key) {
    final millis = prefs.getInt(key);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
