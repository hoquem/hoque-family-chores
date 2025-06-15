import 'package:hoque_family_chores/models/task_summary.dart';

abstract class TaskSummaryServiceInterface {
  Stream<TaskSummary> streamTaskSummary({required String familyId});

  Future<void> updateTaskSummary({
    required String familyId,
    required TaskSummary summary,
  });

  Future<TaskSummary> getTaskSummary({required String familyId});
}
