import 'dart:async';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:collection/collection.dart';

class MockLeaderboardService implements LeaderboardServiceInterface {
  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  final _logger = AppLogger();

  MockLeaderboardService() {
    _logger.i("MockLeaderboardService initialized");
  }

  @override
  Stream<List<LeaderboardEntry>> streamLeaderboard({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 100));
        yield _leaderboards[familyId] ?? [];
      },
      streamName: 'streamLeaderboard',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String familyId,
  }) async {
    return ServiceUtils.handleServiceCall(
      operation: () async => _leaderboards[familyId] ?? [],
      operationName: 'getLeaderboard',
      context: {'familyId': familyId},
    );
  }

  Future<void> updateLeaderboard({
    required String familyId,
    required List<LeaderboardEntry> entries,
  }) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        _leaderboards[familyId] = entries;
      },
      operationName: 'updateLeaderboard',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<LeaderboardEntry?> getLeaderboardEntry({
    required String familyId,
    required String memberId,
  }) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final leaderboard = await getLeaderboard(familyId: familyId);
        return leaderboard.firstWhereOrNull(
          (entry) => entry.member.id == memberId,
        );
      },
      operationName: 'getLeaderboardEntry',
      context: {'familyId': familyId, 'memberId': memberId},
    );
  }

  @override
  Future<void> updateLeaderboardEntry({
    required String familyId,
    required LeaderboardEntry entry,
  }) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final leaderboard = await getLeaderboard(familyId: familyId);
        final index = leaderboard.indexWhere(
          (e) => e.member.id == entry.member.id,
        );
        if (index != -1) {
          leaderboard[index] = entry;
          await updateLeaderboard(familyId: familyId, entries: leaderboard);
        }
      },
      operationName: 'updateLeaderboardEntry',
      context: {'familyId': familyId, 'memberId': entry.member.id},
    );
  }
}
