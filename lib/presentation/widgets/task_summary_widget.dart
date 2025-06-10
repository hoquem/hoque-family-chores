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
    // Fetch summary data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final taskSummaryProvider = Provider.of<TaskSummaryProvider>(context, listen: false);

      final String? currentUserId = authProvider.currentUserId;
      final String? userFamilyId = authProvider.userFamilyId; // Corrected getter

      if (currentUserId != null && userFamilyId != null) {
        taskSummaryProvider.fetchTaskSummary(
          familyId: userFamilyId,
          userId: currentUserId,
        );
      } else {
        logger.w("TaskSummaryWidget: Cannot fetch summary, user or family ID is null.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskSummaryProvider = context.watch<TaskSummaryProvider>();

    if (taskSummaryProvider.state == TaskSummaryState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (taskSummaryProvider.errorMessage != null) {
      return Center(
        child: Text('Error: ${taskSummaryProvider.errorMessage}'),
      );
    }

    final summary = taskSummaryProvider.summary;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Total Completed: ${summary.totalCompleted}'),
            Text('Waiting Overall: ${summary.waitingOverall}'),
            Text('Waiting Assigned: ${summary.waitingAssigned}'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final String? currentUserId = authProvider.currentUserId;
                final String? userFamilyId = authProvider.userFamilyId; // Corrected getter

                if (currentUserId != null && userFamilyId != null) {
                  taskSummaryProvider.fetchTaskSummary(
                    familyId: userFamilyId,
                    userId: currentUserId,
                  );
                } else {
                  logger.w("Cannot refresh summary: user or family ID is null.");
                }
              },
              child: const Text('Refresh Summary'),
            ),
          ],
        ),
      ),
    );
  }
}