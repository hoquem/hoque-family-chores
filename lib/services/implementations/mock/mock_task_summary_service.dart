import 'dart:async';
import 'package:hoque_family_chores/models/task_summary.dart';
import 'package:hoque_family_chores/services/interfaces/task_summary_service_interface.dart';
import 'package:hoque_family_chores/services/utils/service_utils.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class MockTaskSummaryService implements TaskSummaryServiceInterface {
  final Map<String, TaskSummary> _summaries = {};
  final _logger = AppLogger();

  MockTaskSummaryService() {
    _logger.i("MockTaskSummaryService initialized with dummy data.");
  }

  @override
  Stream<TaskSummary> streamTaskSummary({required String familyId}) {
    return ServiceUtils.handleServiceStream(
      stream: () async* {
        await Future.delayed(const Duration(milliseconds: 100));
        yield _summaries[familyId] ?? TaskSummary();
      },
      streamName: 'streamTaskSummary',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<TaskSummary> getTaskSummary({required String familyId}) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _summaries[familyId] ?? TaskSummary();
      },
      operationName: 'getTaskSummary',
      context: {'familyId': familyId},
    );
  }

  @override
  Future<void> updateTaskSummary({
    required String familyId,
    required TaskSummary summary,
  }) async {
    return ServiceUtils.handleServiceCall(
      operation: () async {
        await Future.delayed(const Duration(milliseconds: 100));
        _summaries[familyId] = summary;
      },
      operationName: 'updateTaskSummary',
      context: {'familyId': familyId},
    );
  }
}
