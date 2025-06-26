import 'dart:async';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/test_data/mock_data.dart';
import 'package:collection/collection.dart';

class MockLeaderboardService implements LeaderboardServiceInterface {
  final Map<String, List<LeaderboardEntry>> _leaderboards = {};
  final _logger = AppLogger();

  MockLeaderboardService() {
    _logger.i("MockLeaderboardService: Constructor called");
    _initializeMockData();
  }

  void _initializeMockData() {
    _logger.i("MockLeaderboardService: Starting mock data initialization");
    _logger.d("MockLeaderboardService: MockData.familyId = ${MockData.familyId}");
    _logger.d("MockLeaderboardService: MockData.userProfiles.length = ${MockData.userProfiles.length}");
    
    // Create leaderboard entries from mock user profiles
    final entries = <LeaderboardEntry>[];
    _logger.d("MockLeaderboardService: Processing ${MockData.userProfiles.length} user profiles");
    
    for (int i = 0; i < MockData.userProfiles.length; i++) {
      final userData = MockData.userProfiles[i];
      _logger.d("MockLeaderboardService: Processing user ${userData['id']} - ${userData['displayName']}");
      _logger.d("MockLeaderboardService: User data: $userData");
      
      try {
        final member = FamilyMember(
          id: userData['id'],
          userId: userData['id'],
          familyId: MockData.familyId,
          name: userData['displayName'],
          photoUrl: userData['photoUrl'],
          role: FamilyRole.values.firstWhere(
            (role) => role.name == userData['role'],
          ),
          points: userData['points'],
          joinedAt: DateTime.parse(userData['createdAt']),
          updatedAt: DateTime.parse(userData['lastActive']),
        );
        
        final entry = LeaderboardEntry(
          id: member.id,
          member: member,
          points: userData['points'],
          tasksCompleted: 0, // Mock data doesn't include this, so defaulting to 0
        );
        entries.add(entry);
        _logger.d("MockLeaderboardService: Created entry for ${member.name} with ${userData['points']} points");
      } catch (e, stackTrace) {
        _logger.e("MockLeaderboardService: Error creating entry for user ${userData['id']}: $e", error: e, stackTrace: stackTrace);
      }
    }
    
    // Sort by points descending
    entries.sort((a, b) => b.points.compareTo(a.points));
    _logger.d("MockLeaderboardService: Sorted entries by points");
    
    _leaderboards[MockData.familyId] = entries;
    _logger.i("MockLeaderboardService: Initialized with ${entries.length} leaderboard entries for family ${MockData.familyId}");
    _logger.d("MockLeaderboardService: Available families: ${_leaderboards.keys.toList()}");
    _logger.d("MockLeaderboardService: Entries for ${MockData.familyId}: ${entries.map((e) => '${e.member.name}(${e.points})').toList()}");
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
    _logger.d("MockLeaderboardService: getLeaderboard called for familyId: $familyId");
    _logger.d("MockLeaderboardService: Available families: ${_leaderboards.keys.toList()}");
    _logger.d("MockLeaderboardService: _leaderboards content: $_leaderboards");
    
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final entries = _leaderboards[familyId] ?? [];
        _logger.d("MockLeaderboardService: Returning ${entries.length} entries for family $familyId");
        if (entries.isNotEmpty) {
          _logger.d("MockLeaderboardService: First entry: ${entries.first.member.name} with ${entries.first.points} points");
          _logger.d("MockLeaderboardService: All entries: ${entries.map((e) => '${e.member.name}(${e.points})').toList()}");
        } else {
          _logger.w("MockLeaderboardService: No entries found for family $familyId");
        }
        return entries;
      },
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
