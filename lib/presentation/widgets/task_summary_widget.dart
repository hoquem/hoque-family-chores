// lib/presentation/widgets/task_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';

class TaskSummaryWidget extends StatelessWidget {
  const TaskSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskSummaryProvider>(
      builder: (context, provider, child) {
        if (provider.state == TaskSummaryState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.state == TaskSummaryState.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.errorMessage}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.fetchTaskSummary,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final summary = provider.summary;
        if (summary == null) {
          return const Center(child: Text('No task summary available'));
        }

        // Calculate total tasks as the sum of completed and waiting tasks
        final totalTasks = summary.totalCompleted + summary.waitingOverall;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks Summary',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: provider.fetchTaskSummary,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const Divider(),
                _buildSummaryItem(
                  context,
                  'Waiting',
                  summary.waitingOverall,
                  Colors.orange,
                  Icons.pending_actions,
                ),
                _buildSummaryItem(
                  context,
                  'Assigned',
                  summary.waitingAssigned,
                  Colors.blue,
                  Icons.hourglass_top,
                ),
                _buildSummaryItem(
                  context,
                  'Completed',
                  summary.totalCompleted,
                  Colors.green,
                  Icons.task_alt,
                ),
                _buildSummaryItem(
                  context,
                  'Total',
                  totalTasks,
                  Colors.purple,
                  Icons.assignment,
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalTasks > 0
                      ? summary.totalCompleted / totalTasks
                      : 0.0,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completion Rate: ${totalTasks > 0 ? (summary.totalCompleted / totalTasks * 100).toStringAsFixed(1) : 0}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String title,
    int count,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
