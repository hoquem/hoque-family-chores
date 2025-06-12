import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/enums.dart'; // For AvailableTasksState
import 'package:hoque_family_chores/presentation/providers/available_tasks_provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/services/logging_service.dart';
import 'package:intl/intl.dart';

class QuickTaskPickerWidget extends StatefulWidget {
  const QuickTaskPickerWidget({super.key});

  @override
  State<QuickTaskPickerWidget> createState() => _QuickTaskPickerWidgetState();
}

class _QuickTaskPickerWidgetState extends State<QuickTaskPickerWidget> {
  @override
  void initState() {
    super.initState();
    logger.d("QuickTaskPickerWidget: initState called");
    // Schedule the fetch after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      logger.d("QuickTaskPickerWidget: Post frame callback executing");
      if (mounted) {
        final userProfile = context.read<AuthProvider>().currentUserProfile;
        final familyId = context.read<AuthProvider>().userFamilyId;
        logger.d(
          "QuickTaskPickerWidget: User profile: ${userProfile?.id}, Family ID: $familyId",
        );
        if (userProfile != null && familyId != null) {
          logger.d(
            "QuickTaskPickerWidget: Fetching available tasks for user ${userProfile.id} in family $familyId",
          );
          context.read<AvailableTasksProvider>().fetchAvailableTasks(
            familyId: familyId,
            userId: userProfile.id,
          );
        } else {
          logger.w(
            "QuickTaskPickerWidget: Cannot fetch available tasks - missing user profile or family ID",
          );
        }
      } else {
        logger.w(
          "QuickTaskPickerWidget: Widget not mounted during post frame callback",
        );
      }
    });
  }

  Future<void> _refreshData() async {
    logger.d("QuickTaskPickerWidget: Refreshing data");
    final userProfile = context.read<AuthProvider>().currentUserProfile;
    final familyId = context.read<AuthProvider>().userFamilyId;
    if (userProfile != null && familyId != null) {
      await context.read<AvailableTasksProvider>().fetchAvailableTasks(
        familyId: familyId,
        userId: userProfile.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableTasksProvider = context.watch<AvailableTasksProvider>();
    logger.d(
      "QuickTaskPickerWidget: Building with state ${availableTasksProvider.state}",
    );
    logger.d(
      "QuickTaskPickerWidget: Number of available tasks: ${availableTasksProvider.availableTasks.length}",
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        logger.d(
          "QuickTaskPickerWidget: Layout constraints - width: ${constraints.maxWidth}, height: ${constraints.maxHeight}",
        );
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Quick Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Flexible(child: _buildContent(availableTasksProvider)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(AvailableTasksProvider provider) {
    logger.d(
      "QuickTaskPickerWidget: Building content with state ${provider.state}",
    );
    logger.d(
      "QuickTaskPickerWidget: Available tasks count: ${provider.availableTasks.length}",
    );

    switch (provider.state) {
      case AvailableTasksState.loading:
        logger.d("QuickTaskPickerWidget: Showing loading state");
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(),
          ),
        );
      case AvailableTasksState.error:
        logger.d(
          "QuickTaskPickerWidget: Showing error state: ${provider.errorMessage}",
        );
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error: ${provider.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final userProfile =
                        context.read<AuthProvider>().currentUserProfile;
                    final familyId = context.read<AuthProvider>().userFamilyId;
                    if (userProfile != null && familyId != null) {
                      provider.fetchAvailableTasks(
                        familyId: familyId,
                        userId: userProfile.id,
                      );
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case AvailableTasksState.loaded:
        logger.d(
          "QuickTaskPickerWidget: Loaded state - Tasks count: ${provider.availableTasks.length}",
        );
        if (provider.availableTasks.isEmpty) {
          logger.d(
            "QuickTaskPickerWidget: No tasks available, showing empty state",
          );
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 32, color: Colors.grey),
                  SizedBox(height: 8.0),
                  Text(
                    'No Quick Tasks',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    'There are no quick tasks available at the moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        logger.d(
          "QuickTaskPickerWidget: Building list with ${provider.availableTasks.length} tasks",
        );
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.availableTasks.length,
          itemBuilder: (context, index) {
            final task = provider.availableTasks[index];
            logger.d(
              "QuickTaskPickerWidget: Building task item for task ${task.id}: ${task.title}",
            );

            final dueDate =
                task.dueDate != null
                    ? DateFormat('MMM d, y').format(task.dueDate!)
                    : 'No due date';

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        provider.isClaiming
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : ElevatedButton(
                              onPressed: () async {
                                logger.d(
                                  "QuickTaskPickerWidget: Claiming task ${task.id}",
                                );
                                await provider.claimTask(task.id);
                              },
                              child: const Text('Claim'),
                            ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${task.points} points'),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(dueDate),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      case AvailableTasksState.claiming:
        logger.d("QuickTaskPickerWidget: Showing claiming state");
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}
