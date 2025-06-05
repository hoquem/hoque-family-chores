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
      totalCompleted: 153,
      dueToday: 3,
      waitingOverall: 8,
      waitingAssigned: 5,
      waitingUnassigned: 3,
    );
  }
}