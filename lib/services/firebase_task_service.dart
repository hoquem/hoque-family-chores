// lib/services/firebase_task_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/enums.dart'; // ADDED: Missing import
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

class FirebaseTaskService implements TaskServiceInterface {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Map<String, dynamic>> _tasksCollection;

  FirebaseTaskService() {
    _tasksCollection = _db.collection('tasks');
  }

  // MODIFIED: All method signatures now match the interface with named parameters.
  
  @override
  Stream<List<Task>> streamAllTasks({required String familyId}) {
    return _tasksCollection
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      // MODIFIED: Uses the correct Task.fromMap factory constructor
      return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Stream<List<Task>> streamMyTasks({required String userId}) {
    return _tasksCollection
        .where('assigneeId', isEqualTo: userId)
        .where('status', isNotEqualTo: TaskStatus.completed.name)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Stream<List<Task>> streamAvailableTasks({required String familyId}) {
    return _tasksCollection
        .where('familyId', isEqualTo: familyId)
        .where('assigneeId', isEqualTo: null) // Correct logic for available tasks
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Stream<List<Task>> streamCompletedTasks({required String familyId}) {
    return _tasksCollection
        .where('familyId', isEqualTo: familyId)
        .where('status', whereIn: [TaskStatus.completed.name, TaskStatus.verified.name])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
    });
  }

  @override
  Future<List<Task>> getMyPendingTasks({required String userId}) async {
    final snapshot = await _tasksCollection
        .where('assigneeId', isEqualTo: userId)
        .where('status', isEqualTo: TaskStatus.pending.name)
        .get();
        return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<List<Task>> getUnassignedTasks({required String familyId}) async {
    final snapshot = await _tasksCollection
        .where('familyId', isEqualTo: familyId)
        .where('assigneeId', isEqualTo: null)
        .get();
        return snapshot.docs.map((doc) => Task.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  @override
  Future<void> assignTask({required String taskId, required String userId, required String userName}) async {
    await _tasksCollection.doc(taskId).update({
      'assigneeId': userId,
      'assigneeName': userName,
      'status': TaskStatus.assigned.name,
    });
  }
}