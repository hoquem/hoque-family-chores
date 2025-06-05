// lib/services/mock_task_service.dart
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/services/task_service_interface.dart';

class MockTaskService implements TaskServiceInterface {
  // A list of all mock tasks for the whole family.
  final List<Task> _allTasks = [
    Task(id: 'task_01', title: 'Wash the dishes', assigneeId: 'fm_001', dueDate: DateTime.now()),
    Task(id: 'task_02', title: 'Take out the bins', assigneeId: 'fm_002', dueDate: DateTime.now().add(const Duration(days: 1))),
    Task(id: 'task_03', title: 'Walk the dog', assigneeId: 'fm_001', dueDate: DateTime.now(), priority: TaskPriority.high),
    Task(id: 'task_04', title: 'Clean the bathroom', assigneeId: null, priority: TaskPriority.high), // Unassigned
    Task(id: 'task_05', title: 'Do the grocery shopping', assigneeId: 'fm_001', dueDate: DateTime.now().add(const Duration(days: 2))),
    Task(id: 'task_06', title: 'Water the plants', assigneeId: 'fm_001', isCompleted: true), // Completed, should not show up
    Task(id: 'task_07', title: 'Organise the garage', assigneeId: null), // Unassigned
    Task(id: 'task_08', title: 'Prepare weekly meal plan', assigneeId: 'fm_001'),
  ];

  @override
  Future<List<Task>> getMyPendingTasks(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Filter tasks for the specific user that are not completed
    final pendingTasks = _allTasks
        .where((task) => task.assigneeId == userId && !task.isCompleted)
        .toList();

    // Sort by due date (nulls last) and then by priority
    pendingTasks.sort((a, b) {
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate != null && b.dueDate != null) {
        final dateCompare = a.dueDate!.compareTo(b.dueDate!);
        if (dateCompare != 0) return dateCompare;
      }
      // If due dates are same or both null, sort by priority (high first)
      return b.priority.index.compareTo(a.priority.index);
    });

    return pendingTasks; // <-- This return statement was missing.
  }

  @override
  Future<List<Task>> getUnassignedTasks() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Filter for tasks that are unassigned and not completed
    final unassignedTasks = _allTasks
        .where((task) => task.assigneeId == null && !task.isCompleted)
        .toList();

    return unassignedTasks;
  }

  @override
  Future<void> assignTask({required String taskId, required String userId}) async {
    // Simulate network delay for the update operation
    await Future.delayed(const Duration(seconds: 1));

    // Find the task in our mock list
    final taskIndex = _allTasks.indexWhere((task) => task.id == taskId);

    if (taskIndex != -1) {
      final task = _allTasks[taskIndex];
      // Create a new task instance with the updated assigneeId
      _allTasks[taskIndex] = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        isCompleted: task.isCompleted,
        assigneeId: userId, // Assign the task
        dueDate: task.dueDate,
        priority: task.priority,
      );
      print("MockTaskService: Assigned task '$taskId' to user '$userId'.");
    } else {
      print("MockTaskService: Error - Task with ID '$taskId' not found.");
    }
  }
}