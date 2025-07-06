import 'dart:async';
import '../../domain/repositories/achievement_repository.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/badge.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of AchievementRepository for testing
class MockAchievementRepository implements AchievementRepository {
  final List<Achievement> _achievements = [];
  final Map<String, List<String>> _userAchievements = {}; // userId -> achievementIds
  final StreamController<List<Achievement>> _userAchievementsStreamController = StreamController<List<Achievement>>.broadcast();

  MockAchievementRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock achievements
    final mockAchievements = [
      Achievement(
        id: 'achievement_1',
        title: 'First Task',
        description: 'Complete your first task',
        points: Points(10),
        icon: 'first_task',
        type: BadgeType.taskCompletion,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 25)),
        completedBy: 'user_1',
      ),
      Achievement(
        id: 'achievement_2',
        title: 'Task Master',
        description: 'Complete 10 tasks',
        points: Points(50),
        icon: 'task_master',
        type: BadgeType.taskCompletion,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: DateTime.now().subtract(const Duration(days: 20)),
        completedBy: 'user_1',
      ),
      Achievement(
        id: 'achievement_3',
        title: 'Streak Champion',
        description: 'Complete tasks for 7 days in a row',
        points: Points(100),
        icon: 'streak_champion',
        type: BadgeType.streak,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        completedAt: null,
        completedBy: null,
      ),
    ];

    _achievements.addAll(mockAchievements);

    // Initialize user achievements
    _userAchievements['user_1'] = ['achievement_1', 'achievement_2'];
    _userAchievements['user_2'] = ['achievement_1'];
    _userAchievements['user_3'] = [];
  }

  @override
  Stream<List<Achievement>> streamUserAchievements(UserId userId) {
    return _userAchievementsStreamController.stream
        .where((achievements) => achievements.isNotEmpty);
  }

  @override
  Future<void> grantAchievement(UserId userId, Achievement achievement) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Add achievement to user
      if (!_userAchievements.containsKey(userId.value)) {
        _userAchievements[userId.value] = [];
      }
      
      if (!_userAchievements[userId.value]!.contains(achievement.id)) {
        _userAchievements[userId.value]!.add(achievement.id);
        _userAchievementsStreamController.add(_getUserAchievements(userId));
      }
    } catch (e) {
      throw ServerException('Failed to grant achievement: $e', code: 'ACHIEVEMENT_GRANT_ERROR');
    }
  }

  @override
  Future<void> createAchievement(String familyId, Achievement achievement) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Check if achievement already exists
      final existingAchievement = _achievements.where((a) => a.id == achievement.id).firstOrNull;
      if (existingAchievement != null) {
        throw ValidationException('Achievement already exists', code: 'ACHIEVEMENT_ALREADY_EXISTS');
      }
      
      _achievements.add(achievement);
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to create achievement: $e', code: 'ACHIEVEMENT_CREATE_ERROR');
    }
  }

  @override
  Future<void> updateAchievement(String familyId, String achievementId, Achievement achievement) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final index = _achievements.indexWhere((a) => a.id == achievementId);
      if (index != -1) {
        _achievements[index] = achievement;
      } else {
        throw NotFoundException('Achievement not found', code: 'ACHIEVEMENT_NOT_FOUND');
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to update achievement: $e', code: 'ACHIEVEMENT_UPDATE_ERROR');
    }
  }

  @override
  Future<void> deleteAchievement(String familyId, String achievementId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      final initialLength = _achievements.length;
      _achievements.removeWhere((achievement) => achievement.id == achievementId);
      
      if (_achievements.length == initialLength) {
        throw NotFoundException('Achievement not found', code: 'ACHIEVEMENT_NOT_FOUND');
      }
      
      // Remove achievement from all users
      for (final userId in _userAchievements.keys) {
        _userAchievements[userId]!.remove(achievementId);
      }
    } catch (e) {
      if (e is DataException) rethrow;
      throw ServerException('Failed to delete achievement: $e', code: 'ACHIEVEMENT_DELETE_ERROR');
    }
  }

  /// Helper method to get user achievements
  List<Achievement> _getUserAchievements(UserId userId) {
    final achievementIds = _userAchievements[userId.value] ?? [];
    return _achievements.where((achievement) => achievementIds.contains(achievement.id)).toList();
  }

  /// Dispose the stream controller
  void dispose() {
    _userAchievementsStreamController.close();
  }
} 