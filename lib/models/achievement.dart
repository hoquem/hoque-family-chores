// lib/models/achievement.dart
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp

class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime dateAwarded;

  const Achievement({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateAwarded,
  });

  factory Achievement.fromMap(Map<String, dynamic> data) {
    return Achievement(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? 'No Title',
      description: data['description'] as String? ?? '',
      dateAwarded: (data['dateAwarded'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateAwarded': Timestamp.fromDate(dateAwarded),
    };
  }

  Achievement copyWith({String? id, String? title, String? description, DateTime? dateAwarded}) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateAwarded: dateAwarded ?? this.dateAwarded,
    );
  }
}