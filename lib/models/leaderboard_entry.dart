// lib/models/leaderboard_entry.dart
import 'package:hoque_family_chores/models/family_member.dart';

class LeaderboardEntry {
  final FamilyMember member;
  final int points;
  final int tasksCompleted;

  LeaderboardEntry({
    required this.member,
    required this.points,
    required this.tasksCompleted,
  });
}