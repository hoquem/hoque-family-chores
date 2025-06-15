import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskService {
  final FirebaseFirestore _firestore;
  final _logger = AppLogger();
  String? _currentFamilyId;

  TaskService(this._firestore);

  String? get currentFamilyId => _currentFamilyId;

  Future<List<Task>> getQuickTasks({
    required String familyId,
    required String userId,
  }) async {
    _logger.d('TaskService: Getting quick tasks for family $familyId');
    _currentFamilyId = familyId;

    try {
      final snapshot =
          await _firestore
              .collection('families')
              .doc(familyId)
              .collection('tasks')
              .where('status', isEqualTo: 'available')
              .where('isQuickTask', isEqualTo: true)
              .get();

      final tasks =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Task.fromJson(data);
          }).toList();

      _logger.d('TaskService: Found ${tasks.length} quick tasks');
      return tasks;
    } catch (e, stackTrace) {
      _logger.e(
        'TaskService: Error getting quick tasks',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> assignTask({
    required String taskId,
    required String userId,
  }) async {
    _logger.d('TaskService: Assigning task $taskId to user $userId');
    if (_currentFamilyId == null) {
      throw Exception('No family ID set');
    }

    try {
      await _firestore
          .collection('families')
          .doc(_currentFamilyId)
          .collection('tasks')
          .doc(taskId)
          .update({
            'assigneeId': userId,
            'status': 'assigned',
            'assignedAt': FieldValue.serverTimestamp(),
          });

      _logger.d('TaskService: Task assigned successfully');
    } catch (e, stackTrace) {
      _logger.e(
        'TaskService: Error assigning task',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
