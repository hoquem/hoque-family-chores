import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For TaskStatus
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart'; // Import your provider
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart'; // Needed for authProvider
import 'package:hoque_family_chores/services/logging_service.dart';

class TaskSummaryWidget extends StatefulWidget {
  const TaskSummaryWidget({super.key});

  @override
  State<TaskSummaryWidget> createState() => _TaskSummaryWidgetState();
}

class _TaskSummaryWidgetState extends State<TaskSummaryWidget> {
  @override
  void initState() {
    super.initState();
    logger.d("TaskSummaryWidget: initState called");
    // Schedule the fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.d("TaskSummaryWidget: Post frame callback executing");
      if (mounted) {
        final userProfile = context.read<AuthProvider>().currentUserProfile;
        final familyId = context.read<AuthProvider>().userFamilyId;
        logger.d(
          "TaskSummaryWidget: User profile: ${userProfile?.id}, Family ID: $familyId",
        );
        if (userProfile != null && familyId != null) {
          logger.d(
            "TaskSummaryWidget: Fetching summary for user ${userProfile.id} in family $familyId",
          );
          context.read<TaskSummaryProvider>().fetchTaskSummary(
            familyId: familyId,
            userId: userProfile.id,
          );
        } else {
          logger.w(
            "TaskSummaryWidget: Cannot fetch summary - missing user profile or family ID",
          );
        }
      } else {
        logger.w(
          "TaskSummaryWidget: Widget not mounted during post frame callback",
        );
      }
    });
  }

  Future<void> _refreshData() async {
    logger.d("TaskSummaryWidget: Refreshing data");
    final userProfile = context.read<AuthProvider>().currentUserProfile;
    final familyId = context.read<AuthProvider>().userFamilyId;
    if (userProfile != null && familyId != null) {
      await context.read<TaskSummaryProvider>().fetchTaskSummary(
        familyId: familyId,
        userId: userProfile.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.d("TaskSummaryWidget: build called");
    return Consumer<TaskSummaryProvider>(
      builder: (context, provider, child) {
        logger.d(
          "TaskSummaryWidget: Consumer builder called with state: ${provider.state}",
        );
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: switch (provider.state) {
                TaskSummaryState.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                TaskSummaryState.error => Center(
                  child: Text('Error: ${provider.errorMessage}'),
                ),
                TaskSummaryState.loaded => _buildSummaryContent(
                  provider.summary,
                ),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryContent(TaskSummary summary) {
    logger.d("TaskSummaryWidget: Building summary content with data: $summary");
    // Show "No tasks" message if there are no tasks
    if (summary.totalTasks == 0) {
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
            _buildSummaryRow('Completed', summary.totalCompleted.toString()),
            _buildSummaryRow(
              'Waiting Overall',
              summary.waitingOverall.toString(),
            ),
            _buildSummaryRow(
              'Waiting Assigned',
              summary.waitingAssigned.toString(),
            ),
            _buildSummaryRow('Available', summary.availableTasks.toString()),
            _buildSummaryRow(
              'Needs Revision',
              summary.needsRevisionTasks.toString(),
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
