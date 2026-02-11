import '../../entities/task.dart';
import '../../repositories/task_repository.dart';
import '../../value_objects/family_id.dart';

/// Use case for streaming tasks pending approval
class StreamPendingApprovalsUseCase {
  final TaskRepository _taskRepository;

  StreamPendingApprovalsUseCase(this._taskRepository);

  /// Returns a stream of tasks with pendingApproval status for a family
  /// 
  /// [familyId] - ID of the family
  /// 
  /// Returns [Stream<List<Task>>] of pending approval tasks
  Stream<List<Task>> call(FamilyId familyId) {
    return _taskRepository
        .streamTasks(familyId)
        .map((tasks) => tasks
            .where((task) => task.status == TaskStatus.pendingApproval)
            .toList());
  }
}
