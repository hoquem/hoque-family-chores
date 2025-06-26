// lib/models/leaderboard_entry.dart
import 'package:hoque_family_chores/models/family_member.dart';

class LeaderboardEntry {
  final String id;
  final FamilyMember member;
  final int points;
  final int tasksCompleted;

  LeaderboardEntry._({
    required this.id,
    required this.member,
    required this.points,
    required this.tasksCompleted,
  });

  factory LeaderboardEntry({
    required String id,
    required FamilyMember member,
    required int points,
    required int tasksCompleted,
  }) {
    return LeaderboardEntry._(
      id: id,
      member: member,
      points: points,
      tasksCompleted: tasksCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member.toJson(),
      'points': points,
      'tasksCompleted': tasksCompleted,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      member: FamilyMember.fromJson(json['member'] as Map<String, dynamic>),
      points: json['points'] as int? ?? 0,
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
    );
  }

  LeaderboardEntry copyWith({
    String? id,
    FamilyMember? member,
    int? points,
    int? tasksCompleted,
  }) {
    return LeaderboardEntry(
      id: id ?? this.id,
      member: member ?? this.member,
      points: points ?? this.points,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.id == id &&
        other.member == member &&
        other.points == points &&
        other.tasksCompleted == tasksCompleted;
  }

  @override
  int get hashCode {
    return Object.hash(id, member, points, tasksCompleted);
  }
}
