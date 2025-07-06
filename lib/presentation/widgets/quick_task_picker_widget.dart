import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/available_tasks_notifier.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/value_objects/user_id.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class QuickTaskPickerWidget extends ConsumerWidget {
  const QuickTaskPickerWidget({super.key});

  Future<void> _handleTaskSelection(WidgetRef ref, Task task) async {
    final logger = AppLogger();
    logger.d('QuickTaskPickerWidget: Task selected: ${task.id}');

    try {
      final authState = ref.read(authNotifierProvider);
      final currentUser = authState.user;
      
      if (currentUser != null) {
        logger.d(
          'QuickTaskPickerWidget: Claiming task ${task.id} for user ${currentUser.id}',
        );
        await ref.read(availableTasksNotifierProvider(task.familyId).notifier).claimTask(
          task.id.value,
          currentUser.id,
        );
        logger.d('QuickTaskPickerWidget: Task claimed successfully');
      } else {
        logger.w(
          'QuickTaskPickerWidget: Cannot claim task - missing user profile',
        );
      }
    } catch (e, stackTrace) {
      logger.e(
        'QuickTaskPickerWidget: Error claiming task',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = AppLogger();
    logger.d('QuickTaskPickerWidget: build called');
    
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final familyId = currentUser?.familyId;

    if (currentUser == null || familyId == null) {
      logger.w('QuickTaskPickerWidget: Cannot build widget - missing user or family ID');
      return const Center(child: Text('Please log in to view quick tasks'));
    }

    final availableTasksAsync = ref.watch(availableTasksNotifierProvider(familyId));

    return availableTasksAsync.when(
      data: (availableTasks) {
        logger.d('QuickTaskPickerWidget: Consumer builder called with ${availableTasks.length} tasks');

        if (availableTasks.isEmpty) {
          return const Center(child: Text('No quick tasks available'));
        }

        // Get only the first few tasks as "quick tasks"
        final quickTasks = availableTasks.take(5).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quickTasks.length,
          itemBuilder: (context, index) {
            final task = quickTasks[index];
            return ListTile(
              title: Text(task.title),
              subtitle: Text(task.description),
              trailing: IconButton(
                icon: const Icon(Icons.add_task),
                onPressed: () => _handleTaskSelection(ref, task),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${error.toString()}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
