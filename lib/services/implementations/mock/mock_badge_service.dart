import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/services/interfaces/badge_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockBadgeService implements BadgeServiceInterface {
  final List<Badge> _badges = [];
  final Map<String, List<String>> _userBadges = {};

  MockBadgeService() {
    logger.i("MockBadgeService initialized with empty badges list.");
  }

  @override
  Stream<List<Badge>> streamUserBadges({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        final userBadgeIds = _userBadges[userId] ?? [];
        yield _badges.where((b) => userBadgeIds.contains(b.id)).toList();
      },
      streamName: 'streamUserBadges',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> awardBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!_userBadges.containsKey(userId)) {
          _userBadges[userId] = [];
        }
        if (!_userBadges[userId]!.contains(badgeId)) {
          _userBadges[userId]!.add(badgeId);
        }
      },
      operationName: 'awardBadge',
      context: {'familyId': familyId, 'userId': userId, 'badgeId': badgeId},
    );
  }

  @override
  Future<void> revokeBadge({
    required String familyId,
    required String userId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _userBadges[userId]?.remove(badgeId);
      },
      operationName: 'revokeBadge',
      context: {'familyId': familyId, 'userId': userId, 'badgeId': badgeId},
    );
  }

  @override
  Future<List<Badge>> getBadges({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        return _badges;
      },
      operationName: 'getBadges',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> createBadge({required String familyId, required Badge badge}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _badges.add(badge);
      },
      operationName: 'createBadge',
      context: {'familyId': familyId, 'badgeId': badge.id},
    );
  }

  @override
  Future<void> updateBadge({
    required String familyId,
    required String badgeId,
    required Badge badge,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _badges.indexWhere((b) => b.id == badgeId);
        if (index != -1) {
          _badges[index] = badge;
        }
      },
      operationName: 'updateBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
    );
  }

  @override
  Future<void> deleteBadge({
    required String familyId,
    required String badgeId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _badges.removeWhere((b) => b.id == badgeId);
        // Remove badge from all users
        for (final userId in _userBadges.keys) {
          _userBadges[userId]?.remove(badgeId);
        }
      },
      operationName: 'deleteBadge',
      context: {'familyId': familyId, 'badgeId': badgeId},
    );
  }
}
