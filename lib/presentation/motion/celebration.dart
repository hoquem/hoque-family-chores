import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'celebration.g.dart';

/// The three payoff moments (spec §2). Nothing else may celebrate.
sealed class CelebrationKind {
  const CelebrationKind();
}

class StarsAwarded extends CelebrationKind {
  const StarsAwarded(this.count);
  final int count;
  @override
  bool operator ==(Object other) =>
      other is StarsAwarded && other.count == count;
  @override
  int get hashCode => Object.hash(runtimeType, count);
}

class TreatRedeemed extends CelebrationKind {
  const TreatRedeemed(this.treatName);
  final String treatName;
  @override
  bool operator ==(Object other) =>
      other is TreatRedeemed && other.treatName == treatName;
  @override
  int get hashCode => Object.hash(runtimeType, treatName);
}

class StreakMilestone extends CelebrationKind {
  const StreakMilestone(this.days);
  final int days;
  @override
  bool operator ==(Object other) =>
      other is StreakMilestone && other.days == days;
  @override
  int get hashCode => Object.hash(runtimeType, days);
}

/// A queued celebration. The sequence number exists for the overlay's widget
/// key: two identical payoffs (e.g. +10 twice) must still restart the show.
class QueuedCelebration {
  const QueuedCelebration(this.seq, this.kind);
  final int seq;
  final CelebrationKind kind;
}

/// FIFO of pending celebrations. One plays at a time ("one celebration moment
/// per screen", DESIGN.md); the listener advances it when the overlay ends.
@Riverpod(keepAlive: true)
class CelebrationQueue extends _$CelebrationQueue {
  int _nextSeq = 0;

  @override
  List<QueuedCelebration> build() => const [];

  void celebrate(CelebrationKind kind) =>
      state = [...state, QueuedCelebration(_nextSeq++, kind)];

  void advance() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }
}
