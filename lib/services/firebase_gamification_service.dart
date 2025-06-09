// lib/services/firebase_gamification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/badge.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/services/gamification_service_interface.dart';

class FirebaseGamificationService implements GamificationServiceInterface {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Define references to your Firestore collections
  // It's good practice to have these collections at the top level of your database.
  late final CollectionReference<Map<String, dynamic>> _badgesCollection;
  late final CollectionReference<Map<String, dynamic>> _rewardsCollection;

  FirebaseGamificationService() {
    _badgesCollection = _db.collection('badges');
    _rewardsCollection = _db.collection('rewards');
  }

  /// Fetches the master list of all possible badges from the 'badges' collection.
  @override
  Future<List<Badge>> getPredefinedBadges() async {
    try {
      final snapshot = await _badgesCollection.get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      // Use the Badge.fromMap factory to convert each Firestore document into a Badge object
      return snapshot.docs.map((doc) => Badge.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      debugPrint('Error fetching predefined badges: $e');
      // Return an empty list or rethrow a custom exception
      throw Exception('Could not load badges from the database.');
    }
  }

  /// Fetches the master list of all available rewards from the 'rewards' collection.
  @override
  Future<List<Reward>> getPredefinedRewards() async {
    try {
      final snapshot = await _rewardsCollection.get();
      if (snapshot.docs.isEmpty) {
        return [];
      }
      // Use the Reward.fromMap factory to convert each Firestore document into a Reward object
      return snapshot.docs.map((doc) => Reward.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      debugPrint('Error fetching predefined rewards: $e');
      // Return an empty list or rethrow a custom exception
      throw Exception('Could not load rewards from the database.');
    }
  }

  // You would implement other methods from the interface here. For example:
  /*
  @override
  Future<void> awardBadge(String userId, String badgeId) async {
    // Logic to add a badge to a user's subcollection in Firestore
  }
  */
}