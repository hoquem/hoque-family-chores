import 'dart:async';
import '../../domain/repositories/leaderboard_repository.dart';
import '../../domain/entities/user.dart';
import '../../domain/value_objects/family_id.dart';
import '../../domain/value_objects/user_id.dart';
import '../../domain/value_objects/email.dart';
import '../../domain/value_objects/points.dart';
import '../../core/error/exceptions.dart';

/// Mock implementation of LeaderboardRepository for testing
class MockLeaderboardRepository implements LeaderboardRepository {
  final List<User> _users = [];

  MockLeaderboardRepository() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create some mock users for leaderboard
    final mockUsers = [
      User(
        id: UserId('user_1'),
        name: 'John Doe',
        email: Email('john@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.parent,
        points: Points(450),
        joinedAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_2'),
        name: 'Jane Smith',
        email: Email('jane@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(320),
        joinedAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_3'),
        name: 'Bob Johnson',
        email: Email('bob@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(280),
        joinedAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_4'),
        name: 'Alice Wilson',
        email: Email('alice@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(150),
        joinedAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      User(
        id: UserId('user_5'),
        name: 'Charlie Brown',
        email: Email('charlie@example.com'),
        photoUrl: null,
        familyId: FamilyId('family_1'),
        role: UserRole.child,
        points: Points(90),
        joinedAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];

    _users.addAll(mockUsers);
  }

  @override
  Future<List<User>> getLeaderboard(FamilyId familyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate network delay
      
      // Get users for the specific family and sort by points
      final familyUsers = _users
          .where((user) => user.familyId == familyId)
          .toList()
        ..sort((a, b) => b.points.toInt().compareTo(a.points.toInt()));
      
      return familyUsers;
    } catch (e) {
      throw ServerException('Failed to get leaderboard: $e', code: 'LEADERBOARD_FETCH_ERROR');
    }
  }

  /// Helper method to update user points (for testing)
  void updateUserPoints(UserId userId, Points newPoints) {
    final index = _users.indexWhere((user) => user.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(
        points: newPoints,
        updatedAt: DateTime.now(),
      );
    }
  }
} 