import 'package:hoque_family_chores/models/achievement.dart';
import 'package:hoque_family_chores/services/interfaces/achievement_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockAchievementService implements AchievementServiceInterface {
  final List<Achievement> _achievements = [];
  final _logger = AppLogger();

  MockAchievementService() {
    _logger.i(
      "MockAchievementService initialized with empty achievements list.",
    );
  }

  @override
  Stream<List<Achievement>> streamUserAchievements({required String userId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 300));
        yield _achievements.where((a) => a.completedBy == userId).toList();
      },
      streamName: 'streamUserAchievements',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createAchievement({
    required String familyId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _achievements.add(achievement);
      },
      operationName: 'createAchievement',
      context: {'familyId': familyId, 'achievementId': achievement.id},
    );
  }

  @override
  Future<void> updateAchievement({
    required String familyId,
    required String achievementId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final index = _achievements.indexWhere((a) => a.id == achievementId);
        if (index != -1) {
          _achievements[index] = achievement;
        }
      },
      operationName: 'updateAchievement',
      context: {'familyId': familyId, 'achievementId': achievementId},
    );
  }

  @override
  Future<void> deleteAchievement({
    required String familyId,
    required String achievementId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        _achievements.removeWhere((a) => a.id == achievementId);
      },
      operationName: 'deleteAchievement',
      context: {'familyId': familyId, 'achievementId': achievementId},
    );
  }

  @override
  Future<void> grantAchievement({
    required String userId,
    required Achievement achievement,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 300));
        final completedAchievement = achievement.copyWith(
          completedAt: DateTime.now(),
          completedBy: userId,
        );
        _achievements.add(completedAchievement);
      },
      operationName: 'grantAchievement',
      context: {'userId': userId, 'achievementId': achievement.id},
    );
  }
}
