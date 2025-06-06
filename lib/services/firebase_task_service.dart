// lib/services/firebase_task_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

class FirebaseTaskService implements TaskServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference<Map<String, dynamic>> _tasksCollection;

  FirebaseTaskService() {
    _tasksCollection = _firestore.collection('tasks');
  }

  @override
  Stream<List<Task>> streamAllTasks() {
    final snapshots = _tasksCollection.orderBy('createdAt', descending: true).snapshots();
    return snapshots.map((querySnapshot) {
      return querySnapshot.docs.map((doc) => Task.fromSnapshot(doc)).toList();
    });
  }

  // --- Methods for Dashboard Widgets (Stubbed for now) ---

  @override
  Future<List<Task>> getMyPendingTasks(String userId) {
    // TODO: Implement Firebase logic to fetch tasks assigned to a specific user.
    // This will involve a `where('assigneeId', isEqualTo: userId)` query.
    throw UnimplementedError('getMyPendingTasks has not been implemented for Firebase yet.');
  }

  @override
  Future<List<Task>> getUnassignedTasks() {
    // TODO: Implement Firebase logic to fetch tasks where assigneeId is null.
    // This will involve a `where('assigneeId', isEqualTo: null)` query.
    throw UnimplementedError('getUnassignedTasks has not been implemented for Firebase yet.');
  }

  @override
  Future<void> assignTask({required String taskId, required String userId}) {
    // TODO: Implement Firebase logic to update a task's assigneeId.
    // This will use a Firestore Transaction for data integrity.
    throw UnimplementedError('assignTask has not been implemented for Firebase yet.');
  }

  // --- Methods for Future Stories ---

  @override
  Future<void> createTask(Task task) {
    // TODO: Implement in the "Task Creation" story.
    throw UnimplementedError('createTask has not been implemented yet.');
  }

  @override
  Future<void> updateTask(Task task) {
    // TODO: Implement in stories like "Task Completion" or "Task Editing".
    throw UnimplementedError('updateTask has not been implemented yet.');
  }

  @override
  Future<void> deleteTask(String taskId) {
    // TODO: Implement in the "Task Editing/Deletion" story.
    throw UnimplementedError('deleteTask has not been implemented yet.');
  }
}