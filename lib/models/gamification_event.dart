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

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GamificationEvent.fromJson(Map<String, dynamic> json) {
    return GamificationEvent(
      type: GamificationEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GamificationEventType.pointsEarned,
      ),
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Alias for fromJson for backward compatibility
  factory GamificationEvent.fromMap(Map<String, dynamic> json) {
    return GamificationEvent.fromJson(json);
  }

  /// Factory method for creating gamification events from Firestore documents
  factory GamificationEvent.fromFirestore(Map<String, dynamic> data, String id) {
    final json = Map<String, dynamic>.from(data);
    json['id'] = id; // Ensure ID is included
    return GamificationEvent.fromJson(json);
  }

  /// Convert to Firestore document format
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore uses document ID as the ID
    return json;
  }
}