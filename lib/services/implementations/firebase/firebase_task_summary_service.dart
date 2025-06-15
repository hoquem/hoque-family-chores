import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task_summary.dart';
import 'package:hoque_family_chores/services/interfaces/task_summary_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class FirebaseTaskSummaryService implements TaskSummaryServiceInterface {
  final FirebaseFirestore _firestore;

  FirebaseTaskSummaryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<TaskSummary> streamTaskSummary({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream:
          () => _firestore
              .collection('families')
              .doc(familyId)
              .collection('summaries')
              .doc('task_summary')
              .snapshots()
              .map(
                (doc) => TaskSummary.fromJson({...?doc.data(), 'id': doc.id}),
              ),
      streamName: 'streamTaskSummary',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> updateTaskSummary({
    required String familyId,
    required TaskSummary summary,
  }) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await _firestore
            .collection('families')
            .doc(familyId)
            .collection('summaries')
            .doc('task_summary')
            .set(summary.toJson());
      },
      operationName: 'updateTaskSummary',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<TaskSummary> getTaskSummary({required String familyId}) {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        final doc =
            await _firestore
                .collection('families')
                .doc(familyId)
                .collection('summaries')
                .doc('task_summary')
                .get();
        if (!doc.exists) {
          throw Exception('Task summary not found');
        }
        return TaskSummary.fromJson({...?doc.data(), 'id': doc.id});
      },
      operationName: 'getTaskSummary',
      context: {'familyId': familyId},
    );
  }
}
