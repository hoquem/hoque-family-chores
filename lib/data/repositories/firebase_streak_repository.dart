import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/streak_repository.dart';
import '../../domain/entities/streak.dart';
import '../../domain/value_objects/user_id.dart';
import '../../core/error/exceptions.dart';

/// Firebase implementation of StreakRepository
class FirebaseStreakRepository implements StreakRepository {
  final FirebaseFirestore _firestore;

  FirebaseStreakRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Streak?> getStreak(UserId userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current')
          .get();

      if (!doc.exists) return null;

      return _mapFirestoreToStreak(doc.data()!, userId);
    } catch (e) {
      throw ServerException(
        'Failed to get streak: $e',
        code: 'STREAK_FETCH_ERROR',
      );
    }
  }

  @override
  Stream<Streak?> streamStreak(UserId userId) {
    return _firestore
        .collection('users')
        .doc(userId.value)
        .collection('streakData')
        .doc('current')
        .snapshots()
        .map((doc) =>
            doc.exists ? _mapFirestoreToStreak(doc.data()!, userId) : null);
  }

  @override
  Future<void> createStreak(Streak streak) async {
    try {
      await _firestore
          .collection('users')
          .doc(streak.userId.value)
          .collection('streakData')
          .doc('current')
          .set(_mapStreakToFirestore(streak));
    } catch (e) {
      throw ServerException(
        'Failed to create streak: $e',
        code: 'STREAK_CREATE_ERROR',
      );
    }
  }

  @override
  Future<void> updateStreak(Streak streak) async {
    try {
      await _firestore
          .collection('users')
          .doc(streak.userId.value)
          .collection('streakData')
          .doc('current')
          .set(_mapStreakToFirestore(streak), SetOptions(merge: true));
    } catch (e) {
      throw ServerException(
        'Failed to update streak: $e',
        code: 'STREAK_UPDATE_ERROR',
      );
    }
  }

  @override
  Future<Streak> incrementStreak(UserId userId, DateTime completionDate) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        final Streak currentStreak = doc.exists
            ? _mapFirestoreToStreak(doc.data()!, userId)
            : Streak.initial(userId);

        final newCurrentStreak = currentStreak.currentStreak + 1;
        final newLongestStreak = newCurrentStreak > currentStreak.longestStreak
            ? newCurrentStreak
            : currentStreak.longestStreak;

        final updatedStreak = currentStreak.copyWith(
          currentStreak: newCurrentStreak,
          longestStreak: newLongestStreak,
          lastCompletedDate: completionDate,
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, _mapStreakToFirestore(updatedStreak));
        return updatedStreak;
      });
    } catch (e) {
      throw ServerException(
        'Failed to increment streak: $e',
        code: 'STREAK_INCREMENT_ERROR',
      );
    }
  }

  @override
  Future<Streak> resetStreak(UserId userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        final Streak currentStreak = doc.exists
            ? _mapFirestoreToStreak(doc.data()!, userId)
            : Streak.initial(userId);

        final updatedStreak = currentStreak.copyWith(
          currentStreak: 0,
          lastCompletedDate: null,
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, _mapStreakToFirestore(updatedStreak));
        return updatedStreak;
      });
    } catch (e) {
      throw ServerException(
        'Failed to reset streak: $e',
        code: 'STREAK_RESET_ERROR',
      );
    }
  }

  @override
  Future<Streak> useFreeze(UserId userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw ServerException(
            'Streak not found',
            code: 'STREAK_NOT_FOUND',
          );
        }

        final currentStreak = _mapFirestoreToStreak(doc.data()!, userId);

        if (currentStreak.freezesAvailable <= 0) {
          throw ServerException(
            'No freezes available',
            code: 'NO_FREEZES_AVAILABLE',
          );
        }

        final updatedStreak = currentStreak.copyWith(
          freezesAvailable: currentStreak.freezesAvailable - 1,
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, _mapStreakToFirestore(updatedStreak));
        return updatedStreak;
      });
    } catch (e) {
      throw ServerException(
        'Failed to use freeze: $e',
        code: 'STREAK_FREEZE_ERROR',
      );
    }
  }

  @override
  Future<Streak> purchaseFreeze(UserId userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current');

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        final Streak currentStreak = doc.exists
            ? _mapFirestoreToStreak(doc.data()!, userId)
            : Streak.initial(userId);

        // Max 5 freezes
        if (currentStreak.freezesAvailable >= 5) {
          throw ServerException(
            'Maximum freezes reached (5)',
            code: 'MAX_FREEZES_REACHED',
          );
        }

        final updatedStreak = currentStreak.copyWith(
          freezesAvailable: currentStreak.freezesAvailable + 1,
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, _mapStreakToFirestore(updatedStreak));
        return updatedStreak;
      });
    } catch (e) {
      throw ServerException(
        'Failed to purchase freeze: $e',
        code: 'STREAK_PURCHASE_ERROR',
      );
    }
  }

  @override
  Future<void> awardMilestoneBonus(
    UserId userId,
    int milestoneDay,
    int starAmount,
  ) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId.value)
          .collection('streakData')
          .doc('current');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);

        if (!doc.exists) {
          throw ServerException(
            'Streak not found',
            code: 'STREAK_NOT_FOUND',
          );
        }

        final currentStreak = _mapFirestoreToStreak(doc.data()!, userId);
        final milestones = [...currentStreak.milestonesAchieved];
        
        if (!milestones.contains(milestoneDay)) {
          milestones.add(milestoneDay);
        }

        final updatedStreak = currentStreak.copyWith(
          milestonesAchieved: milestones,
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, _mapStreakToFirestore(updatedStreak));
      });
    } catch (e) {
      throw ServerException(
        'Failed to award milestone: $e',
        code: 'MILESTONE_AWARD_ERROR',
      );
    }
  }

  /// Maps Firestore data to Streak entity
  Streak _mapFirestoreToStreak(Map<String, dynamic> data, UserId userId) {
    return Streak(
      userId: userId,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastCompletedDate: data['lastCompletedDate'] != null
          ? (data['lastCompletedDate'] as Timestamp).toDate()
          : null,
      freezesAvailable: data['freezesAvailable'] as int? ?? 0,
      milestonesAchieved:
          (data['milestonesAchieved'] as List<dynamic>?)?.cast<int>() ?? [],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Maps Streak entity to Firestore data
  Map<String, dynamic> _mapStreakToFirestore(Streak streak) {
    return {
      'currentStreak': streak.currentStreak,
      'longestStreak': streak.longestStreak,
      'lastCompletedDate': streak.lastCompletedDate != null
          ? Timestamp.fromDate(streak.lastCompletedDate!)
          : null,
      'freezesAvailable': streak.freezesAvailable,
      'milestonesAchieved': streak.milestonesAchieved,
      'updatedAt': Timestamp.fromDate(streak.updatedAt),
    };
  }
}
