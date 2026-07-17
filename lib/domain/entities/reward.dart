import 'package:equatable/equatable.dart';

import '../value_objects/family_id.dart';
import '../value_objects/points.dart';
import '../value_objects/user_id.dart';

/// How long the family has to make good on a reward once it is claimed.
///
/// A property of the reward, not a negotiation at claim time: "Tennis, this
/// month" is the promise being offered. The deadline is not the interesting
/// part of the feature — the promise and the refund are — so there is no date
/// picker and nothing to haggle over.
enum RewardTimeframe {
  /// No deadline. The claimant can still ask for their stars back at any time.
  openEnded,
  thisWeek,
  thisMonth;

  /// When a reward claimed at [now] must be delivered by, or null if open.
  DateTime? dueFrom(DateTime now) => switch (this) {
        RewardTimeframe.openEnded => null,
        // End of Sunday. weekday is 1..7 with Monday == 1.
        RewardTimeframe.thisWeek =>
          DateTime(now.year, now.month, now.day + (8 - now.weekday)),
        // Midnight on the 1st of next month, i.e. the end of this one.
        RewardTimeframe.thisMonth => DateTime(now.year, now.month + 1, 1),
      };

  String get label => switch (this) {
        RewardTimeframe.openEnded => 'Any time',
        RewardTimeframe.thisWeek => 'This week',
        RewardTimeframe.thisMonth => 'This month',
      };
}

/// Something a family member can spend their stars on.
///
/// Deliberately experiences rather than goods — a walk in the park, tennis, a
/// family meal. Chores buy family time, not screen time or pocket money. See
/// PRODUCT.md: a parent hands this to their child, and it must not read as
/// paying them off.
///
/// Anyone in the family can create one. A family is peers, not a hierarchy, and
/// a child proposing "bike ride with Dad" is the feature working.
class Reward extends Equatable {
  const Reward({
    required this.id,
    required this.familyId,
    required this.title,
    required this.cost,
    required this.timeframe,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final FamilyId familyId;
  final String title;
  final Points cost;
  final RewardTimeframe timeframe;

  /// Whoever proposed it. Not a permission — anyone may claim any reward,
  /// including the person who created it.
  final UserId createdBy;
  final DateTime createdAt;

  Reward copyWith({
    String? id,
    String? title,
    Points? cost,
    RewardTimeframe? timeframe,
  }) =>
      Reward(
        id: id ?? this.id,
        familyId: familyId,
        title: title ?? this.title,
        cost: cost ?? this.cost,
        timeframe: timeframe ?? this.timeframe,
        createdBy: createdBy,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, familyId, title, cost, timeframe, createdBy, createdAt];
}
