// lib/services/mock_task_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

class MockTaskService implements TaskServiceInterface {
  final List<Task> _allTasks = [
    Task(
        id: 'task_01',
        title: 'Wash the dishes',
        description: 'Load and run the dishwasher after dinner.',
        points: 10,
        createdAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
        priority: TaskPriority.medium,
        status: TaskStatus.assigned,
        assigneeId: 'fm_001',
        assigneeName: 'Mahmudul Hoque',
        creatorId: 'fm_002'),
    Task(
        id: 'task_02',
        title: 'Take out the bins',
        description: 'Recycling and general waste bins to the curb.',
        points: 5,
        createdAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        priority: TaskPriority.low,
        status: TaskStatus.assigned,
        assigneeId: 'fm_002',
        creatorId: 'fm_002'),
    Task(
        id: 'task_03',
        title: 'Walk the dog',
        description: 'A 30-minute walk around the park.',
        points: 20,
        createdAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now()),
        priority: TaskPriority.high,
        status: TaskStatus.assigned,
        assigneeId: 'fm_001',
        creatorId: 'fm_003'),
    Task(
        id: 'task_04',
        title: 'Clean the bathroom',
        description:
            'Clean the upstairs bathroom, including toilet, sink, and shower.',
        points: 50,
        createdAt: Timestamp.now(),
        priority: TaskPriority.high,
        status: TaskStatus.available,
        creatorId: 'fm_003'),
    Task(
        id: 'task_05',
        title: 'Do the grocery shopping',
        description: 'Buy all items from the shared shopping list.',
        points: 25,
        createdAt: Timestamp.now(),
        dueDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        priority: TaskPriority.medium,
        status: TaskStatus.assigned,
        assigneeId: 'fm_001',
        creatorId: 'fm_003'),
    Task(
        id: 'task_06',
        title: 'Water the plants',
        description: 'All indoor and outdoor plants.',
        points: 5,
        createdAt: Timestamp.now(),
        priority: TaskPriority.low,
        status: TaskStatus.completed, // Status is now 'completed'
        assigneeId: 'fm_001',
        creatorId: 'fm_002'),
    Task(
        id: 'task_07',
        title: 'Organise the garage',
        description: 'Clear out clutter and sweep the floor.',
        points: 100,
        createdAt: Timestamp.now(),
        priority: TaskPriority.low,
        status: TaskStatus.available, // Status is 'available'
        creatorId: 'fm_002'),
    Task(
        id: 'task_08',
        title: 'Prepare weekly meal plan',
        description: 'Plan out meals for the upcoming week.',
        points: 15,
        createdAt: Timestamp.now(),
        priority: TaskPriority.medium,
        status: TaskStatus.assigned,
        assigneeId: 'fm_001',
        creatorId: 'fm_002'),
  ];

  @override
  Stream<List<Task>> streamAllTasks() {
    return Stream.value(_allTasks);
  }

    @override
  Stream<List<Task>> streamMyTasks(String userId) {
    final myTasks = _allTasks
        .where((task) => task.assigneeId == userId && task.status != TaskStatus.completed)
        .toList();
    return Stream.value(myTasks);
  }

  @override
  Stream<List<Task>> streamAvailableTasks() {
    final availableTasks = _allTasks
        .where((task) => task.status == TaskStatus.available)
        .toList();
    return Stream.value(availableTasks);
  }

  @override
  Stream<List<Task>> streamCompletedTasks() {
    final completedTasks = _allTasks
        .where((task) => task.status == TaskStatus.completed)
        .toList();
    return Stream.value(completedTasks);
  }

  @override
  Future<List<Task>> getMyPendingTasks(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final pendingTasks = _allTasks
        // CORRECTED: Filter by status, not the old 'isCompleted' property
        .where((task) =>
            task.assigneeId == userId && task.status != TaskStatus.completed)
        .toList();

    pendingTasks.sort((a, b) => (a.dueDate ?? Timestamp(0, 0))
        .compareTo(b.dueDate ?? Timestamp(0, 0)));
    return pendingTasks;
  }

  @override
  Future<List<Task>> getUnassignedTasks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // CORRECTED: Filter by status, not assigneeId and isCompleted
    return _allTasks
        .where((task) => task.status == TaskStatus.available)
        .toList();
  }

  @override
  Future<void> assignTask({required String taskId, required String userId}) async {
    await Future.delayed(const Duration(seconds: 1));
    final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      final oldTask = _allTasks[taskIndex];
      // CORRECTED: Re-create the task instance without the non-existent 'isCompleted' field
      _allTasks[taskIndex] = Task(
        id: oldTask.id,
        title: oldTask.title,
        description: oldTask.description,
        points: oldTask.points,
        createdAt: oldTask.createdAt,
        dueDate: oldTask.dueDate,
        priority: oldTask.priority,
        creatorId: oldTask.creatorId,
        status: TaskStatus.assigned, // Change status to assigned
        assigneeId: userId, // Set the new assignee ID
      );
      print("MockTaskService: Assigned task '$taskId' to user '$userId'.");
    }
  }

  @override
  Future<void> createTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newTask = Task(
        id: 'task_${Random().nextInt(999)}',
        title: task.title,
        description: task.description,
        points: task.points,
        createdAt: task.createdAt,
        priority: task.priority,
        status: task.status,
        creatorId: task.creatorId);
    _allTasks.add(newTask);
    print("MockTaskService: Created task '${newTask.title}'.");
  }

  @override
  Future<void> updateTask(Task task) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final taskIndex = _allTasks.indexWhere((t) => t.id == task.id);
    if (taskIndex != -1) {
      _allTasks[taskIndex] = task;
      print("MockTaskService: Updated task '${task.title}'.");
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _allTasks.removeWhere((task) => task.id == taskId);
    print("MockTaskService: Deleted task '$taskId'.");
  }
}