import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart'; // Import your provider
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart'; // Needed for authProvider
import 'package:hoque_family_chores/utils/logger.dart';

class TaskSummaryWidget extends StatefulWidget {
  const TaskSummaryWidget({super.key});

  @override
  State<TaskSummaryWidget> createState() => _TaskSummaryWidgetState();
}

class _TaskSummaryWidgetState extends State<TaskSummaryWidget> {
  @override
  void initState() {
    super.initState();
    logger.i("[TaskSummaryWidget] initState called");
    // Schedule the fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.d("[TaskSummaryWidget] Post frame callback executing");
      if (mounted) {
        final userProfile = context.read<AuthProvider>().currentUserProfile;
        final familyId = context.read<AuthProvider>().userFamilyId;
        logger.d("[TaskSummaryWidget] User profile: ${userProfile?.member.id}, Family ID: $familyId");
        
        if (userProfile != null && familyId != null) {
          logger.i("[TaskSummaryWidget] Fetching summary for user ${userProfile.member.id} in family $familyId");
          try {
            context.read<TaskSummaryProvider>().refreshSummary(
              familyId: familyId,
              userId: userProfile.member.id,
            );
          } catch (e, s) {
            logger.e("[TaskSummaryWidget] Error fetching summary: $e", error: e, stackTrace: s);
          }
        } else {
          logger.w("[TaskSummaryWidget] Cannot fetch summary - missing user profile or family ID. UserProfile: $userProfile, FamilyId: $familyId");
        }
      } else {
        logger.w("[TaskSummaryWidget] Widget not mounted during post frame callback");
      }
    });
  }

  Future<void> _refreshData() async {
    logger.i("[TaskSummaryWidget] Refreshing data");
    final userProfile = context.read<AuthProvider>().currentUserProfile;
    final familyId = context.read<AuthProvider>().userFamilyId;
    
    if (userProfile != null && familyId != null) {
      logger.d("[TaskSummaryWidget] Refreshing summary for user ${userProfile.member.id} in family $familyId");
      try {
        await context.read<TaskSummaryProvider>().refreshSummary(
          familyId: familyId,
          userId: userProfile.member.id,
        );
        logger.i("[TaskSummaryWidget] Data refresh completed successfully");
      } catch (e, s) {
        logger.e("[TaskSummaryWidget] Error refreshing data: $e", error: e, stackTrace: s);
      }
    } else {
      logger.w("[TaskSummaryWidget] Cannot refresh data - missing user profile or family ID. UserProfile: $userProfile, FamilyId: $familyId");
    }
  }

  @override
  Widget build(BuildContext context) {
    logger.d("[TaskSummaryWidget] Building widget");
    return Consumer<TaskSummaryProvider>(
      builder: (context, provider, child) {
        logger.d("[TaskSummaryWidget] Consumer builder called with state: ${provider.state}");
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: IntrinsicHeight(
              child: switch (provider.state) {
                TaskSummaryState.loading => const Center(
                  child: CircularProgressIndicator(),
                ),
                TaskSummaryState.error => Center(
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
                        'Error: ${provider.errorMessage ?? 'Unknown error'}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
