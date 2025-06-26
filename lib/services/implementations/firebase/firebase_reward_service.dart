import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/reward.dart';
import 'package:hoque_family_chores/services/interfaces/reward_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';

class FirebaseRewardService implements RewardServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseRewardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Reward>> streamRewards({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('rewards')
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) =>
                              Reward.fromJson({...doc.data(), 'id': doc.id}),
                        )
                        .toList(),
              ),
      streamName: 'streamRewards',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Reward>> getRewards({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final rewardsSnapshot =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('rewards')
                .get();
        return rewardsSnapshot.docs
            .map((doc) => Reward.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getRewards',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> createReward({
    required String familyId,
    required Reward reward,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        // Let Firestore auto-generate the document ID
        final docRef = _firestore
            .collection('families')
            .doc(familyId)
            .collection('rewards')
            .doc();
        
        // Create the reward with the auto-generated ID
        final rewardWithId = reward.copyWith(id: docRef.id);
        
        await docRef.set(rewardWithId.toJson());
      },
      operationName: 'createReward',
      context: {'familyId': familyId, 'rewardId': reward.id},
    );
  }

  @override
  Future<void> updateReward({
    required String familyId,
    required String rewardId,
    required Reward reward,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('rewards')
            .doc(rewardId)
            .update(reward.toJson());
      },
      operationName: 'updateReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
    );
  }

  @override
  Future<void> deleteReward({
    required String familyId,
    required String rewardId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('rewards')
            .doc(rewardId)
            .delete();
      },
      operationName: 'deleteReward',
      context: {'familyId': familyId, 'rewardId': rewardId},
    );
  }

  @override
  Future<void> redeemReward({
    required String familyId,
    required String userId,
    required String rewardId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final batch = _firestore.batch();

        // Get reward data
        final rewardDoc =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('rewards')
                .doc(rewardId)
                .get();

        if (!rewardDoc.exists || rewardDoc.data() == null) {
          throw Exception('Reward not found');
        }

        final reward = Reward.fromJson({
          ...rewardDoc.data()!,
          'id': rewardDoc.id,
        });

        // Add redemption record
        final redemptionRef =
            _firestore
                .collection('families')
                .doc(familyId)
                .collection('rewards')
                .doc(rewardId)
                .collection('redemptions')
                .doc();

        batch.set(redemptionRef, {
          'userId': userId,
          'redeemedAt': FieldValue.serverTimestamp(),
          'points': reward.pointsCost,
        });

        // Update user's points
        final userRef = _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc(userId);

        batch.update(userRef, {
          'points': FieldValue.increment(-reward.pointsCost),
        });

        await batch.commit();
      },
      operationName: 'redeemReward',
      context: {'familyId': familyId, 'userId': userId, 'rewardId': rewardId},
    );
  }
}
