// lib/presentation/providers/task_summary_provider.dart
import 'package:flutter/foundation.dart';
import '../../models/task_summary.dart';
import '../../services/task_summary_service_interface.dart';

enum TaskSummaryState { initial, loading, loaded, error }

class TaskSummaryProvider with ChangeNotifier {
  final TaskSummaryServiceInterface _summaryService;

  TaskSummaryProvider(this._summaryService);

  TaskSummaryState _state = TaskSummaryState.initial;
  TaskSummary? _summary;
  String _errorMessage = '';

  TaskSummaryState get state => _state;
  TaskSummary? get summary => _summary;
  String get errorMessage => _errorMessage;

  Future<void> fetchTaskSummary() async {
    _state = TaskSummaryState.loading;
    notifyListeners();

    try {
      _summary = await _summaryService.getTaskSummary();
      _state = TaskSummaryState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TaskSummaryState.error;
    }
    notifyListeners();
  }
}