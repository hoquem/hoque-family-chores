import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:hoque_family_chores/services/interfaces/task_service_interface.dart';
import 'package:hoque_family_chores/utils/exceptions.dart';
import 'package:hoque_family_chores/utils/logger.dart';

enum MyTasksState { initial, loading, loaded, error }

class MyTasksProvider with ChangeNotifier {
  final TaskServiceInterface _taskService;
  final AuthProviderBase _authProvider;
  StreamSubscription? _tasksSubscription;
  final _logger = AppLogger();

  MyTasksState _state = MyTasksState.initial;
  String? _errorMessage;
  List<Task> _tasks = [];

  MyTasksState get state => _state;
  String? get errorMessage => _errorMessage;
  List<Task> get tasks => _tasks;

  MyTasksProvider({
    required TaskServiceInterface taskService,
    required AuthProviderBase authProvider,
  }) : _taskService = taskService,
       _authProvider = authProvider {
    _logger.d('MyTasksProvider: Initialized with taskService and authProvider');
    _authProvider.addListener(_onAuthChanged);
    _logger.d('MyTasksProvider: Added auth listener');
  }

  void _onAuthChanged() {
    _logger.d("MyTasksProvider: Auth state changed - userId: ${_authProvider.currentUserId}, familyId: ${_authProvider.userFamilyId}");
    _listenToMyTasks();
  }

  void _listenToMyTasks() {
    _logger.d("MyTasksProvider: _listenToMyTasks called");
    _logger.d("MyTasksProvider: taskService: true");
    _logger.d("MyTasksProvider: currentUserId: ${_authProvider.currentUserId}");
    _logger.d("MyTasksProvider: userFamilyId: ${_authProvider.userFamilyId}");
    
    if (_authProvider.currentUserId == null ||
        _authProvider.userFamilyId == null) {
      _logger.w("MyTasksProvider: Cannot listen to tasks - missing dependencies");
      return;
    }

    _logger.d("MyTasksProvider: Starting to listen to tasks for user ${_authProvider.currentUserId} in family ${_authProvider.userFamilyId}");
    _state = MyTasksState.loading;
    notifyListeners();

    _tasksSubscription?.cancel();
    _tasksSubscription = _taskService
        .streamTasksByAssignee(
          familyId: _authProvider.userFamilyId!,
          assigneeId: _authProvider.currentUserId!,
        )
        .listen(
          (tasks) {
            _logger.d("MyTasksProvider: Received [1m${tasks.length}[0m tasks from stream");
            _tasks = tasks;
            _state = MyTasksState.loaded;
            notifyListeners();
            _logger.d("MyTasksProvider: State changed to loaded with ${_tasks.length} tasks");
          },
          onError: (e, s) {
            _logger.e("MyTasksProvider: Error listening to my tasks", error: e, stackTrace: s);
            _errorMessage =
                e is AppException ? e.message : "An unknown error occurred.";
            _state = MyTasksState.error;
            notifyListeners();
          },
        );
  }

  Future<void> refresh() async {
    _logger.d("MyTasksProvider: refresh() called");
    _listenToMyTasks();
  }

  @override
  void dispose() {
    _logger.d("MyTasksProvider: dispose() called");
    _tasksSubscription?.cancel();
    _authProvider.removeListener(_onAuthChanged);
    super.dispose();
  }
}
