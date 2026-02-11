import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/streak.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';

void main() {
  group('Streak Entity', () {
    late UserId userId;

    setUp(() {
      userId = UserId('test-user-123');
    });

    test('should create initial streak with zero values', () {
      // Act
      final streak = Streak.initial(userId);

      // Assert
      expect(streak.userId, userId);
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.lastCompletedDate, isNull);
      expect(streak.freezesAvailable, 0);
      expect(streak.milestonesAchieved, isEmpty);
    });

    test('should identify active streak correctly', () {
      // Arrange
      final streak = Streak.initial(userId).copyWith(currentStreak: 5);

      // Assert
      expect(streak.hasActiveStreak, isTrue);
    });

    test('should identify no streak correctly', () {
      // Arrange
      final streak = Streak.initial(userId);

      // Assert
      expect(streak.hasActiveStreak, isFalse);
    });

    test('should identify "on fire" state at 30+ days', () {
      // Arrange
      final streak = Streak.initial(userId).copyWith(currentStreak: 30);

      // Assert
      expect(streak.isOnFire, isTrue);
      expect(streak.state, StreakState.onFire);
    });

    test('should identify legendary state at 100+ days', () {
      // Arrange
      final streak = Streak.initial(userId).copyWith(currentStreak: 100);

      // Assert
      expect(streak.isLegendary, isTrue);
      expect(streak.state, StreakState.legendary);
    });

    test('should return correct state for different streak counts', () {
      expect(
        Streak.initial(userId).copyWith(currentStreak: 0).state,
        StreakState.none,
      );
      expect(
        Streak.initial(userId).copyWith(currentStreak: 5).state,
        StreakState.active,
      );
      expect(
        Streak.initial(userId).copyWith(currentStreak: 7).state,
        StreakState.hot,
      );
      expect(
        Streak.initial(userId).copyWith(currentStreak: 30).state,
        StreakState.onFire,
      );
      expect(
        Streak.initial(userId).copyWith(currentStreak: 100).state,
        StreakState.legendary,
      );
    });

    test('should check milestone achievement correctly', () {
      // Arrange
      final streak = Streak.initial(userId).copyWith(
        milestonesAchieved: [7, 30],
      );

      // Assert
      expect(streak.hasMilestone(7), isTrue);
      expect(streak.hasMilestone(30), isTrue);
      expect(streak.hasMilestone(100), isFalse);
    });

    test('should copy with updated fields', () {
      // Arrange
      final original = Streak.initial(userId);
      final now = DateTime.now();

      // Act
      final updated = original.copyWith(
        currentStreak: 10,
        longestStreak: 10,
        lastCompletedDate: now,
        freezesAvailable: 2,
      );

      // Assert
      expect(updated.currentStreak, 10);
      expect(updated.longestStreak, 10);
      expect(updated.lastCompletedDate, now);
      expect(updated.freezesAvailable, 2);
      expect(updated.userId, original.userId);
    });
  });

  group('StreakMilestone', () {
    test('should have correct milestone values', () {
      expect(StreakMilestone.bronze.days, 7);
      expect(StreakMilestone.bronze.starReward, 50);
      expect(StreakMilestone.bronze.title, 'Week Warrior');

      expect(StreakMilestone.silver.days, 30);
      expect(StreakMilestone.silver.starReward, 200);
      expect(StreakMilestone.silver.title, 'Monthly Master');

      expect(StreakMilestone.gold.days, 100);
      expect(StreakMilestone.gold.starReward, 1000);
      expect(StreakMilestone.gold.title, 'Century Legend');
    });

    test('should find milestone for specific days', () {
      expect(StreakMilestone.forDays(7), StreakMilestone.bronze);
      expect(StreakMilestone.forDays(30), StreakMilestone.silver);
      expect(StreakMilestone.forDays(100), StreakMilestone.gold);
      expect(StreakMilestone.forDays(5), isNull);
    });
  });
}
