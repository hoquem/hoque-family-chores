import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/widgets/my_tasks_widget.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/my_tasks_notifier.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = AppLogger();
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.user?.id;
    final familyId = authState.user?.familyId;

    Future<void> refreshData() async {
      logger.d('TasksScreen: Refreshing data');
      if (userId != null && familyId != null) {
        ref.read(myTasksNotifierProvider(familyId, userId).notifier).refresh();
      }
    }

    logger.d('TasksScreen: Building screen');
    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: MyTasksWidget(),
        ),
      ),
    );
  }
}
