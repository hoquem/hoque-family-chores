import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/family_id.dart';
import 'package:hoque_family_chores/domain/value_objects/task_id.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';

part 'pending_approvals_notifier.g.dart';

/// Manages pending approval tasks for a family.
/// 
/// This notifier streams tasks with pendingApproval status and provides
/// methods for approving and rejecting tasks.
@riverpod
class PendingApprovalsNotifier extends _$PendingApprovalsNotifier {
  final _logger = AppLogger();

  @override
  Stream<List<Task>> build(FamilyId familyId) {
    _logger.d('PendingApprovalsNotifier: Building for family $familyId');
    
    final streamPendingApprovalsUseCase = ref.read(streamPendingApprovalsUseCaseProvider);
    return streamPendingApprovalsUseCase(familyId);
  }

  /// Approves a task and awards stars to the assignee
  Future<void> approveTask({
    required TaskId taskId,
    required UserId approverId,
    required FamilyId familyId,
  }) async {
    _logger.d('PendingApprovalsNotifier: Approving task $taskId');
    
    try {
      final approveTaskUseCase = ref.read(approveTaskUseCaseProvider);
      final result = await approveTaskUseCase(
        taskId: taskId,
        approverId: approverId,
        familyId: familyId,
      );
      
      result.fold(
        (failure) {
          _logger.e('PendingApprovalsNotifier: Failed to approve task', error: failure.message);
          throw Exception(failure.message);
        },
        (task) {
          _logger.d('PendingApprovalsNotifier: Task approved successfully');
          // Stream will automatically update
        },
      );
    } catch (e) {
      _logger.e('PendingApprovalsNotifier: Error approving task', error: e);
      rethrow;
    }
  }

  /// Rejects a task with an optional reason
  Future<void> rejectTask({
    required TaskId taskId,
    String? reason,
  }) async {
    _logger.d('PendingApprovalsNotifier: Rejecting task $taskId');
    
    try {
      final rejectTaskUseCase = ref.read(rejectTaskUseCaseProvider);
      final result = await rejectTaskUseCase(
        taskId: taskId,
        comments: reason,
      );
      
      result.fold(
        (failure) {
          _logger.e('PendingApprovalsNotifier: Failed to reject task', error: failure.message);
          throw Exception(failure.message);
        },
        (_) {
          _logger.d('PendingApprovalsNotifier: Task rejected successfully');
          // Stream will automatically update
        },
      );
    } catch (e) {
      _logger.e('PendingApprovalsNotifier: Error rejecting task', error: e);
      rethrow;
    }
  }
}
