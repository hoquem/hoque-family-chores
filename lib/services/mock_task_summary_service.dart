// lib/services/mock_task_summary_service.dart
import '../models/task_summary.dart';
import 'task_summary_service_interface.dart';

class MockTaskSummaryService implements TaskSummaryServiceInterface {
  @override
  Future<TaskSummary> getTaskSummary() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return hardcoded mock data
    return TaskSummary(
      id: 'summary',
      totalTasks: 164,
      completedTasks: 153,
      pendingTasks: 8,
      availableTasks: 3,
      needsRevisionTasks: 0,
      assignedTasks: 5,
      dueToday: 3,
    );
  }
}