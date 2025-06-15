import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/family.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/services/interfaces/family_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseFamilyService implements FamilyServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseFamilyService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<Family?> streamFamily({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore.collection('families').doc(familyId).snapshots().map(
            (doc) {
              if (doc.exists && doc.data() != null) {
                return Family.fromJson({...?doc.data(), 'id': doc.id});
              }
              return null;
            },
          ),
      streamName: 'streamFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<Family?> getFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final familyDoc =
            await _firestore.collection('families').doc(familyId).get();
        if (!familyDoc.exists) {
          return null;
        }
        return Family.fromJson({...?familyDoc.data(), 'id': familyDoc.id});
      },
      operationName: 'getFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<Family>> getFamiliesForUser({required String userId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final snapshot =
            await _firestore
                .collection('families')
                .where('memberIds', arrayContains: userId)
                .get();
        return snapshot.docs
            .map((doc) => Family.fromJson({...?doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getFamiliesForUser',
      context: {'userId': userId},
    );
  }

  @override
  Future<void> createFamily({required Family family}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(family.id)
            .set(family.toJson());
      },
      operationName: 'createFamily',
      context: {'familyId': family.id},
    );
  }

  @override
  Future<void> updateFamily({
    required String familyId,
    required Family family,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .update(family.toJson());
      },
      operationName: 'updateFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> deleteFamily({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore.collection('families').doc(familyId).delete();
      },
      operationName: 'deleteFamily',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> addUserToFamily({
    required String familyId,
    required String userId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore.collection('families').doc(familyId).update({
          'memberIds': FieldValue.arrayUnion([userId]),
        });
      },
      operationName: 'addUserToFamily',
      context: {'familyId': familyId, 'userId': userId},
    );
  }

  @override
  Future<void> removeUserFromFamily({
    required String familyId,
    required String userId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore.collection('families').doc(familyId).update({
          'memberIds': FieldValue.arrayRemove([userId]),
        });
      },
      operationName: 'removeUserFromFamily',
      context: {'familyId': familyId, 'userId': userId},
    );
  }

  @override
  Stream<List<FamilyMember>> streamFamilyMembers({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('members')
              .snapshots()
              .map(
                (snapshot) =>
                    snapshot.docs
                        .map(
                          (doc) => FamilyMember.fromJson({
                            ...?doc.data(),
                            'id': doc.id,
                          }),
                        )
                        .toList(),
              ),
      streamName: 'streamFamilyMembers',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<List<FamilyMember>> getFamilyMembers({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final membersSnapshot =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('members')
                .get();
        return membersSnapshot.docs
            .map((doc) => FamilyMember.fromJson({...?doc.data(), 'id': doc.id}))
            .toList();
      },
      operationName: 'getFamilyMembers',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> updateFamilyMember({
    required String familyId,
    required String memberId,
    required FamilyMember member,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc(memberId)
            .update(member.toJson());
      },
      operationName: 'updateFamilyMember',
      context: {'familyId': familyId, 'memberId': memberId},
    );
  }

  @override
  Future<void> deleteFamilyMember({
    required String familyId,
    required String memberId,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc(memberId)
            .delete();
      },
      operationName: 'deleteFamilyMember',
      context: {'familyId': familyId, 'memberId': memberId},
    );
  }
}
