import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider_base.dart';
import 'package:hoque_family_chores/presentation/providers/task_provider.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/shared_enums.dart';
import 'package:hoque_family_chores/utils/logger.dart';

class QuickTaskPickerWidget extends StatefulWidget {
  const QuickTaskPickerWidget({super.key});

  @override
  State<QuickTaskPickerWidget> createState() => _QuickTaskPickerWidgetState();
}

class _QuickTaskPickerWidgetState extends State<QuickTaskPickerWidget> {
  final _logger = AppLogger();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.d('QuickTaskPickerWidget: initState called');
    // Schedule the load after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadQuickTasks();
      }
    });
  }

  Future<void> _loadQuickTasks() async {
    _logger.d('QuickTaskPickerWidget: Loading quick tasks');
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = context.read<AuthProviderBase>().currentUserProfile;
      final familyId = context.read<AuthProviderBase>().userFamilyId;

      if (userProfile != null && familyId != null) {
        _logger.d(
          'QuickTaskPickerWidget: Fetching quick tasks for user ${userProfile.member.id} in family $familyId',
        );
        await context.read<TaskProvider>().fetchQuickTasks(
          familyId: familyId,
          userId: userProfile.member.id,
        );
      } else {
        _logger.w(
          'QuickTaskPickerWidget: Cannot fetch quick tasks - missing user profile or family ID',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'QuickTaskPickerWidget: Error loading quick tasks',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTaskSelection(Task task) async {
    _logger.d('QuickTaskPickerWidget: Task selected: ${task.id}');
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = context.read<AuthProviderBase>().currentUserProfile;
      final familyId = context.read<AuthProviderBase>().userFamilyId;
      
      if (userProfile != null && familyId != null) {
        _logger.d(
          'QuickTaskPickerWidget: Assigning task ${task.id} to user ${userProfile.member.id} in family $familyId',
        );
        await context.read<TaskProvider>().assignTask(
          taskId: task.id,
          userId: userProfile.member.id,
          familyId: familyId,
        );
        _logger.d('QuickTaskPickerWidget: Task assigned successfully');
      } else {
        _logger.w(
          'QuickTaskPickerWidget: Cannot assign task - missing user profile or family ID',
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        'QuickTaskPickerWidget: Error assigning task',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.d('QuickTaskPickerWidget: build called');
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        _logger.d(
          'QuickTaskPickerWidget: Consumer builder called with state: ${provider.state}',
        );

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final quickTasks = provider.quickTasks;
        if (quickTasks.isEmpty) {
          return const Center(child: Text('No quick tasks available'));
        }

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
                onPressed: () => _handleTaskSelection(task),
              ),
            );
          },
        );
      },
    );
  }
}
