// lib/services/mock_leaderboard_service.dart
import 'dart:math';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/family_service_interface.dart';
import 'package:hoque_family_chores/services/mock_family_service.dart';
import 'package:hoque_family_chores/services/leaderboard_service_interface.dart';

class MockLeaderboardService implements LeaderboardServiceInterface {
  // We can depend on our existing family service to get the members
  final FamilyServiceInterface _familyService = MockFamilyService();

  @override
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final familyMembers = await _familyService.getFamilyMembers();
    final random = Random();

    // Create leaderboard entries with random data
    List<LeaderboardEntry> leaderboard = familyMembers.map((member) {
      int points = random.nextInt(200) + 20; // Random points between 20 and 220
      int tasksCompleted = (points / (random.nextInt(10) + 5)).round(); // Loosely related tasks
      return LeaderboardEntry(
        id: member.id,
        member: member,
        points: points,
        tasksCompleted: tasksCompleted,
      );
    }).toList();

    // Sort the leaderboard as per the acceptance criteria
    leaderboard.sort((a, b) {
      int pointsCompare = b.points.compareTo(a.points); // Descending points
      if (pointsCompare != 0) {
        return pointsCompare;
      }
      // If points are tied, sort by tasks completed (descending)
      return b.tasksCompleted.compareTo(a.tasksCompleted);
    });

    return leaderboard;
  }
}