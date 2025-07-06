import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_summary_notifier.dart';
import 'package:hoque_family_chores/domain/entities/task_summary.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TaskSummaryWidget extends ConsumerWidget {
  const TaskSummaryWidget({super.key});

  Future<void> _refreshData(WidgetRef ref) async {
    logger.i("[TaskSummaryWidget] Refreshing data");
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;
    
    if (currentUser != null && familyId != null) {
      logger.d("[TaskSummaryWidget] Refreshing summary for user ${currentUser.id} in family $familyId");
      try {
        await ref.read(taskSummaryNotifierProvider(familyId).notifier).refresh();
        logger.i("[TaskSummaryWidget] Data refresh completed successfully");
      } catch (e, s) {
        logger.e("[TaskSummaryWidget] Error refreshing data: $e", error: e, stackTrace: s);
      }
    } else {
      logger.w("[TaskSummaryWidget] Cannot refresh data - missing user profile or family ID. User: $currentUser, FamilyId: $familyId");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.d("[TaskSummaryWidget] Building widget");
    
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser == null || familyId == null) {
      logger.w("[TaskSummaryWidget] Cannot build widget - missing user or family ID");
      return const Center(
        child: Text('Please log in to view task summary'),
      );
    }

    final summaryAsync = ref.watch(taskSummaryNotifierProvider(familyId));

    return RefreshIndicator(
      onRefresh: () => _refreshData(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: IntrinsicHeight(
          child: summaryAsync.when(
            data: (summary) => _buildSummaryContent(summary),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryContent(TaskSummary summary) {
    logger.d("[TaskSummaryWidget] Building summary content with data: $summary");
    // Show "No tasks" message if there are no tasks
    if (summary.totalTasks == 0) {
      logger.d("[TaskSummaryWidget] No tasks found - showing empty state");
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.task_alt, size: 48, color: Colors.grey),
              const SizedBox(height: 16.0),
              const Text(
                'No Tasks',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'There are no tasks in your family yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            _buildSummaryRow('Total Tasks', summary.totalTasks.toString()),
            _buildSummaryRow('Completed', summary.completedTasks.toString()),
            _buildSummaryRow(
              'Pending',
              summary.pendingTasks.toString(),
            ),
            _buildSummaryRow(
              'Available',
              summary.availableTasks.toString(),
            ),
            _buildSummaryRow('Assigned', summary.assignedTasks.toString()),
            _buildSummaryRow(
              'Completion Rate',
              '${summary.completionPercentage}%',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
