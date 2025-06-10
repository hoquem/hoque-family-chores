// lib/models/gamification_event.dart

enum GamificationEventType {
  pointsEarned,
  levelUp,
  badgeUnlocked,
  rewardRedeemed,
  streakIncreased,
  achievementUnlocked,
}

class GamificationEvent {
  final GamificationEventType type;
  final String message;
  final DateTime timestamp;

  GamificationEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}