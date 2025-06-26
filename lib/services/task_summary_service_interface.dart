// lib/services/task_summary_service_interface.dart
import '../models/task_summary.dart';

abstract class TaskSummaryServiceInterface {
  /// Fetches a summary of task metrics.
  Future<TaskSummary> getTaskSummary();
}