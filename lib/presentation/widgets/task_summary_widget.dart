// lib/presentation/widgets/task_summary_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/task_summary.dart'; // Import the model
import 'package:hoque_family_chores/presentation/providers/task_summary_provider.dart';

// Helper class to hold data for each metric card for cleaner code
class _MetricData {
  final String title;
  final String value;
  final Color color;

  _MetricData({required this.title, required this.value, required this.color});
}

class TaskSummaryWidget extends StatelessWidget {
  const TaskSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Consumer is another great way to react to provider changes.
    // It's functionally similar to context.watch within the build method.
    return Consumer<TaskSummaryProvider>(
      builder: (context, provider, child) {
        switch (provider.state) {
          case TaskSummaryState.loading:
          case TaskSummaryState.initial:
            // Show placeholders/shimmer effect while loading for better UX
            return const Center(child: CircularProgressIndicator());
          case TaskSummaryState.error:
            return Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Could not load task summary: ${provider.errorMessage}'),
              ),
            );
          case TaskSummaryState.loaded:
            if (provider.summary == null) {
              return const Card(child: ListTile(title: Text('No summary data available.')));
            }
            final summary = provider.summary!;

            // Create a list of our metric data to build the grid
            final List<_MetricData> metrics = [
              _MetricData(title: 'Due Today', value: summary.dueToday.toString(), color: Colors.orange.shade700),
              _MetricData(title: 'Awaiting Completion', value: summary.waitingOverall.toString(), color: Colors.red.shade600),
              _MetricData(title: 'Assigned & Waiting', value: summary.waitingAssigned.toString(), color: Colors.blue.shade600),
              _MetricData(title: 'Unassigned & Waiting', value: summary.waitingUnassigned.toString(), color: Colors.grey.shade600),
              _MetricData(title: 'Total Completed', value: summary.totalCompleted.toString(), color: Colors.green.shade600),
            ];

            return GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // Disable grid's own scrolling
              shrinkWrap: true, // Make grid only take up the space it needs
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns
                crossAxisSpacing: 12.0, // Horizontal space between cards
                mainAxisSpacing: 12.0, // Vertical space between cards
                childAspectRatio: 1.2, // Width-to-height ratio for each card. Adjust to make taller/shorter.
              ),
              itemCount: metrics.length,
              itemBuilder: (context, index) {
                final metric = metrics[index];
                return _buildMetricCard(metric.title, metric.value, metric.color);
              },
            );
        }
      },
    );
  }

  // Helper widget for styling each metric item, now with a fixed aspect ratio
  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}