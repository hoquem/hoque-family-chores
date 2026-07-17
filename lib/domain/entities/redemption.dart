import 'package:equatable/equatable.dart';

import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// Where a claim has got to.
enum RedemptionStatus {
  /// Stars are spent and the family owes the claimant an outing.
  claimed,

  /// The claimant confirmed it happened. The stars stay spent.
  fulfilled,

  /// It did not happen — the claimant said so, or the deadline passed. The
  /// stars went back.
  refunded,
}

/// A claim on a reward: the family owes someone an afternoon.
///
/// This is not a purchase. Every reward worth having — a walk, tennis, a meal
/// out — needs another person to show up, so a claim is a promise with a life:
/// claimed → fulfilled, or claimed → refunded.
///
/// **The claimant is the judge.** Every other approval in this app runs the
/// other way, with a parent ruling on a child's work. Here the family made a
/// promise and the child decides whether it was kept. If it was not, they get
/// their stars back. The app is willing to say the family failed.
class Redemption extends Equatable {
  const Redemption({
    required this.id,
    required this.familyId,
    required this.rewardId,
    required this.rewardTitle,
    required this.cost,
    required this.claimedBy,
    required this.claimedAt,
    required this.status,
    this.dueBy,
    this.settledAt,
  });

  final String id;
  final FamilyId familyId;
  final String rewardId;

  /// Copied, not looked up. The reward it came from can be renamed or
  /// repriced later, and a claim already paid for must not be quietly
  /// rewritten. History is not a live query.
  final String rewardTitle;
  final Points cost;

  final UserId claimedBy;
  final DateTime claimedAt;
  final RedemptionStatus status;

  /// When the family has to deliver by, or null for an open-ended reward.
  /// Derived from the reward's timeframe at the moment of claiming.
  final DateTime? dueBy;

  /// When it was fulfilled or refunded.
  final DateTime? settledAt;

  /// Whether this claim's deadline has passed without it being settled.
  ///
  /// Drives a lazy refund: rather than a scheduled job, an expired claim
  /// settles itself the next time anyone reads it. No cron, no server, and a
  /// family that forgets does not quietly keep the stars.
  bool isExpired(DateTime now) =>
      status == RedemptionStatus.claimed &&
      dueBy != null &&
      !now.isBefore(dueBy!);

  /// Whether the claimant is still owed this outing.
  bool get isOutstanding => status == RedemptionStatus.claimed;

  Redemption settle(RedemptionStatus outcome, DateTime at) => Redemption(
        id: id,
        familyId: familyId,
        rewardId: rewardId,
        rewardTitle: rewardTitle,
        cost: cost,
        claimedBy: claimedBy,
        claimedAt: claimedAt,
        status: outcome,
        dueBy: dueBy,
        settledAt: at,
      );

  @override
  List<Object?> get props => [
        id,
        familyId,
        rewardId,
        rewardTitle,
        cost,
        claimedBy,
        claimedAt,
        status,
        dueBy,
        settledAt,
      ];
}
