import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/leaderboard_entry.dart';
import 'package:hoque_family_chores/services/interfaces/leaderboard_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseLeaderboardService implements LeaderboardServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<LeaderboardEntry>> streamLeaderboard({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('leaderboard')
              .orderBy('points', descending: true)
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => LeaderboardEntry.fromJson({
                            ...doc.data(),
                            'id': doc.id,
                          }),
                        )
                        .toList(),
              ),
      streamName: 'streamLeaderboard',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> updateLeaderboardEntry({
    required String familyId,
    required LeaderboardEntry entry,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('leaderboard')
            .doc(entry.id)
            .set(entry.toJson());
      },
      operationName: 'updateLeaderboardEntry',
      context: {'familyId': familyId, 'entryId': entry.id},
    );
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final snapshot =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('leaderboard')
                .orderBy('points', descending: true)
                .get();
        return snapshot.docs
            .map(
              (doc) =>
                  LeaderboardEntry.fromJson({
                    ...doc.data(),
                    'id': doc.id,
                  }),
            )
            .toList();
      },
      operationName: 'getLeaderboard',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<LeaderboardEntry?> getLeaderboardEntry({
    required String familyId,
    required String memberId,
  }) async {
    try {
      final doc =
          await _firestore
              .collection('families')
              .doc(familyId)
              .collection('leaderboard')
              .doc(memberId)
              .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return LeaderboardEntry.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
    } catch (e) {
      AppLogger().e('Error getting leaderboard entry: $e', error: e);
      rethrow;
    }
  }
}
