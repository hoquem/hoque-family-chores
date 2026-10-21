import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';
import 'package:hoque_family_chores/presentation/motion/celebration.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';

part 'star_award_watcher.g.dart';

/// Watches the signed-in user's star balance and celebrates increases.
///
/// Cold start sets a baseline (spec §2): the first emission for a user records
/// state and celebrates nothing, so history never replays at launch. Only
/// deltas observed after the baseline celebrate. Decreases (spending) are the
/// treat flow's job, not ours.
///
/// A refunded treat also raises the balance, but it is stars coming back, not
/// stars earned. Only the claimant can settle their own claim, so the refund
/// always starts on this device: the treat flow announces it with
/// [expectRefund] before settling, and the rise it causes is absorbed.
@Riverpod(keepAlive: true)
class StarAwardWatcher extends _$StarAwardWatcher {
  String? _userId;
  int? _points;
  int _expectedRefunds = 0;

  /// Treats the next [amount] of balance rise as a refund, not an award.
  void expectRefund(Points amount) => _expectedRefunds += amount.value;

  /// Withdraws an [expectRefund] whose settle failed, so no refund will come.
  void cancelRefund(Points amount) {
    _expectedRefunds = max(0, _expectedRefunds - amount.value);
  }

  @override
  void build() {
    // ref.listen does not fire for the initial value — we must baseline
    // explicitly so the first change is treated as a delta, not a cold start.
    _baseline(ref.read(authNotifierProvider));

    ref.listen(authNotifierProvider, (_, next) {
      _onChange(next);
    });
  }

  void _baseline(AuthState state) {
    final user = state.user;
    if (user == null) {
      _userId = null;
      _points = null;
      return;
    }
    _userId = user.id.value;
    _points = user.points.value;
  }

  void _onChange(AuthState next) {
    final user = next.user;
    if (user == null) {
      _userId = null;
      _points = null;
      _expectedRefunds = 0;
      return;
    }
    final sameUser = user.id.value == _userId;
    final previous = _points;
    _userId = user.id.value;
    _points = user.points.value;
    if (!sameUser || previous == null) {
      _expectedRefunds = 0;
      return; // baseline, no celebration
    }
    final rise = user.points.value - previous;
    if (rise <= 0) return;
    final refunded = min(rise, _expectedRefunds);
    _expectedRefunds -= refunded;
    final delta = rise - refunded;
    if (delta > 0) {
      ref
          .read(celebrationQueueProvider.notifier)
          .celebrate(StarsAwarded(delta));
    }
  }
}
