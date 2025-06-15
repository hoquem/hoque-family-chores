import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';
import '../models/enums.dart';

/// A service that handles gamification features using Firebase.
class FirebaseGamificationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseGamificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  /// Updates the user's points in Firestore.
  ///
  /// [points] The number of points to add to the user's current points.
  Future<void> _updateUserPoints(int points) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userDoc = _firestore.collection('users').doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      if (!snapshot.exists) {
        transaction.set(userDoc, {
          'points': points,
          'level': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final currentPoints = snapshot.data()?['points'] as int? ?? 0;
      final newPoints = currentPoints + points;
      transaction.update(userDoc, {'points': newPoints});

      // Check if user should level up
      final currentLevel = snapshot.data()?['level'] as int? ?? 1;
      final newLevel = _getLevelForPoints(newPoints);
      if (newLevel > currentLevel) {
        transaction.update(userDoc, {'level': newLevel});
      }
    });
  }

  /// Calculates the level based on the total points.
  ///
  /// [points] The total points to calculate the level from.
  /// Returns the calculated level.
  int _getLevelForPoints(int points) {
    // Simple level calculation: 1 level per 100 points
    return (points ~/ 100) + 1;
  }

  /// Records a completed task in Firestore.
  ///
  /// [task] The task that was completed.
  Future<void> recordCompletedTask(Task task) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final points = _calculatePointsForTask(task);
    await _updateUserPoints(points);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('completed_tasks')
        .add({
          'taskId': task.id,
          'title': task.title,
          'points': points,
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Calculates points for a completed task.
  ///
  /// [task] The task to calculate points for.
  /// Returns the number of points earned.
  int _calculatePointsForTask(Task task) {
    // Base points for completing any task
    int points = task.points;

    // Bonus points for difficulty
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        points += 5;
        break;
      case TaskDifficulty.medium:
        points += 10;
        break;
      case TaskDifficulty.hard:
        points += 15;
        break;
      case TaskDifficulty.challenging:
        points += 20;
        break;
    }

    return points;
  }

  /// Gets the current user's gamification data.
  ///
  /// Returns a map containing the user's points and level, or null if not found.
  Future<Map<String, dynamic>?> getUserGamificationData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return {
      'points': doc.data()?['points'] ?? 0,
      'level': doc.data()?['level'] ?? 1,
    };
  }
}
