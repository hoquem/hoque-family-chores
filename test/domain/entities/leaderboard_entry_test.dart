import 'package:flutter_test/flutter_test.dart';
import 'package:hoque_family_chores/domain/entities/leaderboard_entry.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/domain/value_objects/points.dart';

void main() {
  group('LeaderboardEntry', () {
    test('creates and holds values', () {
      final entry = LeaderboardEntry(
        userId: UserId('u1'),
        userName: 'Test',
        points: Points(100),
        completedTasks: 5,
        rank: 1,
      );
      expect(entry.rank, 1);
      expect(entry.completedTasks, 5);
    });

    test('copyWith', () {
      final entry = LeaderboardEntry(
        userId: UserId('u1'),
        userName: 'Test',
        points: Points(100),
        completedTasks: 5,
        rank: 1,
      );
      final copy = entry.copyWith(rank: 2);
      expect(copy.rank, 2);
      expect(copy.userName, 'Test');
    });

    test('equality', () {
      final a = LeaderboardEntry(
        userId: UserId('u1'),
        userName: 'Test',
        points: Points(100),
        completedTasks: 5,
        rank: 1,
      );
      final b = LeaderboardEntry(
        userId: UserId('u1'),
        userName: 'Test',
        points: Points(100),
        completedTasks: 5,
        rank: 1,
      );
      expect(a, equals(b));
    });

    test('toString', () {
      final entry = LeaderboardEntry(
        userId: UserId('u1'),
        userName: 'Test',
        points: Points(100),
        completedTasks: 5,
        rank: 1,
      );
      expect(entry.toString(), contains('Test'));
    });
  });
}
