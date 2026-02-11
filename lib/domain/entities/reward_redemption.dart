import 'package:equatable/equatable.dart';
import '../value_objects/family_id.dart';
import '../value_objects/user_id.dart';

/// Domain entity representing a reward redemption request
class RewardRedemption extends Equatable {
  final String id;
  final String rewardId;
  final String rewardName;
  final String rewardIconEmoji;
  final int starCost;
  final UserId userId;
  final FamilyId familyId;
  final RedemptionStatus status;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedByUserId;
  final String? rejectionReason;

  const RewardRedemption({
    required this.id,
    required this.rewardId,
    required this.rewardName,
    required this.rewardIconEmoji,
    required this.starCost,
    required this.userId,
    required this.familyId,
    required this.status,
    required this.requestedAt,
    this.processedAt,
    this.processedByUserId,
    this.rejectionReason,
  });

  /// Creates a copy of this redemption with updated fields
  RewardRedemption copyWith({
    String? id,
    String? rewardId,
    String? rewardName,
    String? rewardIconEmoji,
    int? starCost,
    UserId? userId,
    FamilyId? familyId,
    RedemptionStatus? status,
    DateTime? requestedAt,
    DateTime? processedAt,
    String? processedByUserId,
    String? rejectionReason,
  }) {
    return RewardRedemption(
      id: id ?? this.id,
      rewardId: rewardId ?? this.rewardId,
      rewardName: rewardName ?? this.rewardName,
      rewardIconEmoji: rewardIconEmoji ?? this.rewardIconEmoji,
      starCost: starCost ?? this.starCost,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedByUserId: processedByUserId ?? this.processedByUserId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  /// Check if this redemption is pending
  bool get isPending => status == RedemptionStatus.pending;

  /// Check if this redemption is approved
  bool get isApproved => status == RedemptionStatus.approved;

  /// Check if this redemption is rejected
  bool get isRejected => status == RedemptionStatus.rejected;

  @override
  List<Object?> get props => [
        id,
        rewardId,
        rewardName,
        rewardIconEmoji,
        starCost,
        userId,
        familyId,
        status,
        requestedAt,
        processedAt,
        processedByUserId,
        rejectionReason,
      ];
}

/// Status of a reward redemption request
enum RedemptionStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RedemptionStatus.pending:
        return 'Pending';
      case RedemptionStatus.approved:
        return 'Approved';
      case RedemptionStatus.rejected:
        return 'Rejected';
    }
  }
}
