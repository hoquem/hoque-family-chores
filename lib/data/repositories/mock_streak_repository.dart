import 'dart:async';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/entities/streak.dart';
import '../../domain/value_objects/user_id.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of StreakRepository for testing and offline mode
class MockStreakRepository implements StreakRepository {
  final Map<String, Streak> _streaks = {};
  final StreamController<Streak?> _streamController =
      StreamController<Streak?>.broadcast();

  @override
  Future<Streak?> getStreak(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
    return _streaks[userId.value];
  }

  @override
  Stream<Streak?> streamStreak(UserId userId) {
    return _streamController.stream
        .where((streak) => streak?.userId == userId)
        .distinct();
  }

  @override
  Future<void> createStreak(Streak streak) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _streaks[streak.userId.value] = streak;
    _streamController.add(streak);
  }

  @override
  Future<void> updateStreak(Streak streak) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _streaks[streak.userId.value] = streak;
    _streamController.add(streak);
  }

  @override
  Future<Streak> incrementStreak(UserId userId, DateTime completionDate) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final currentStreak = _streaks[userId.value] ?? Streak.initial(userId);
    final newCurrentStreak = currentStreak.currentStreak + 1;
    final newLongestStreak = newCurrentStreak > currentStreak.longestStreak
        ? newCurrentStreak
        : currentStreak.longestStreak;

    final updatedStreak = currentStreak.copyWith(
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      lastCompletedDate: completionDate,
      updatedAt: DateTime.now(),
    );

    _streaks[userId.value] = updatedStreak;
    _streamController.add(updatedStreak);
    return updatedStreak;
  }

  @override
  Future<Streak> resetStreak(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final currentStreak = _streaks[userId.value] ?? Streak.initial(userId);
    final updatedStreak = currentStreak.copyWith(
      currentStreak: 0,
      lastCompletedDate: null,
      updatedAt: DateTime.now(),
    );

    _streaks[userId.value] = updatedStreak;
    _streamController.add(updatedStreak);
    return updatedStreak;
  }

  @override
  Future<Streak> useFreeze(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final currentStreak = _streaks[userId.value];
    if (currentStreak == null) {
      throw ServerException('Streak not found', code: 'STREAK_NOT_FOUND');
    }

    if (currentStreak.freezesAvailable <= 0) {
      throw ServerException('No freezes available', code: 'NO_FREEZES_AVAILABLE');
    }

    final updatedStreak = currentStreak.copyWith(
      freezesAvailable: currentStreak.freezesAvailable - 1,
      updatedAt: DateTime.now(),
    );

    _streaks[userId.value] = updatedStreak;
    _streamController.add(updatedStreak);
    return updatedStreak;
  }

  @override
  Future<Streak> purchaseFreeze(UserId userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final currentStreak = _streaks[userId.value] ?? Streak.initial(userId);
    
    if (currentStreak.freezesAvailable >= 5) {
      throw ServerException('Maximum freezes reached (5)', code: 'MAX_FREEZES_REACHED');
    }

    final updatedStreak = currentStreak.copyWith(
      freezesAvailable: currentStreak.freezesAvailable + 1,
      updatedAt: DateTime.now(),
    );

    _streaks[userId.value] = updatedStreak;
    _streamController.add(updatedStreak);
    return updatedStreak;
  }

  @override
  Future<void> awardMilestoneBonus(
    UserId userId,
    int milestoneDay,
    int starAmount,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final currentStreak = _streaks[userId.value];
    if (currentStreak == null) {
      throw ServerException('Streak not found', code: 'STREAK_NOT_FOUND');
    }

    final milestones = [...currentStreak.milestonesAchieved];
    if (!milestones.contains(milestoneDay)) {
      milestones.add(milestoneDay);
    }

    final updatedStreak = currentStreak.copyWith(
      milestonesAchieved: milestones,
      updatedAt: DateTime.now(),
    );

    _streaks[userId.value] = updatedStreak;
    _streamController.add(updatedStreak);
  }

  /// Helper method for testing - add mock data
  void addMockStreak(Streak streak) {
    _streaks[streak.userId.value] = streak;
    _streamController.add(streak);
  }

  /// Helper method for testing - clear all data
  void clear() {
    _streaks.clear();
  }

  void dispose() {
    _streamController.close();
  }
}
