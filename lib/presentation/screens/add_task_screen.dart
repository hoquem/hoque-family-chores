import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_creation_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add this import for TimeoutException

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  User? _selectedAssignee;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  final _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not properly authenticated'),
          backgroundColor: context.tokens.brickDeep,
        ),
      );
      return;
    }

    try {
      _logger.i('Creating new task for family ${currentUser.familyId.value} by user ${currentUser.id.value}');

      await ref.read(taskCreationNotifierProvider.notifier).createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        difficulty: _selectedDifficulty,
        familyId: currentUser.familyId,
        creatorId: currentUser.id,
        assignedTo: _selectedAssignee,
        dueDate: _dueDate,
      );

      final creationState = ref.read(taskCreationNotifierProvider);
      if (creationState.error != null) {
        _logger.e('Task creation failed: ${creationState.error}');
        return;
      }

      _logger.i('Task created successfully');

      // Refresh the task list so the new task appears immediately.
      ref.invalidate(taskListNotifierProvider(currentUser.familyId));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.e('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: ${e.toString()}'),
            backgroundColor: context.tokens.brickDeep,
          ),
        );
      }
    }
  }

  Future<void> _loadFamilyMembers() async {
    final authState = ref.read(authNotifierProvider);
    final currentUser = authState.user;

    if (currentUser != null) {
      // The family members will be loaded automatically by the provider
      _logger.i('Family members will be loaded by provider for family: ${currentUser.familyId.value}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final taskCreationState = ref.watch(taskCreationNotifierProvider);
    final currentUser = authState.user;

    // Watch family members if we have a family ID
    final familyMembersAsync = currentUser != null 
        ? ref.watch(familyMembersNotifierProvider(currentUser.familyId))
        : null;

    _logger.i("Navigating to Add New Task screen.");

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Task')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              key: const Key('task_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a task title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('task_description_field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _EffortSizeField(
              key: const Key('task_difficulty_dropdown'),
              value: _selectedDifficulty,
              onChanged: (d) => setState(() => _selectedDifficulty = d),
            ),
            const SizedBox(height: 16),
            // Family members dropdown
            if (familyMembersAsync != null) ...[
              familyMembersAsync.when(
                data: (familyMembers) => DropdownButtonFormField<User?>(
                  decoration: const InputDecoration(
                    labelText: 'Assign To (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedAssignee,
                  items: [
                    const DropdownMenuItem<User?>(
                      value: null,
                      child: Text('Leave Unassigned'),
                    ),
                    if (currentUser != null)
                      DropdownMenuItem<User?>(
                        value: currentUser,
                        child: Text('Me (${currentUser.name})'),
                      ),
                    ...familyMembers
                        .where((member) => member.id.value != currentUser?.id.value)
                        .map((member) => DropdownMenuItem<User?>(
                              value: member,
                              child: Text(member.name),
                            ))
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAssignee = value;
                    });
                  },
                ),
                loading: () => DropdownButtonFormField<User?>(
                  decoration: const InputDecoration(
                    labelText: 'Assign To (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Loading family members…',
                  ),
                  value: null,
                  items: const [],
                  onChanged: null,
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.tokens.brick.withValues(alpha: 0.12),
                    border: Border.all(color: context.tokens.brick.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Could not load family members.',
                          style: TextStyle(color: context.tokens.brick),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(familyMembersNotifierProvider(
                                    currentUser!.familyId)
                                .notifier)
                            .refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              DropdownButtonFormField<User?>(
                decoration: const InputDecoration(
                  labelText: 'Assign To (Optional)',
                  border: OutlineInputBorder(),
                ),
                value: null,
                items: const [],
                onChanged: null,
              ),
            ],
            const SizedBox(height: 16),
            // An InkWell wrapping a field reads as text, not as something you
            // can act on; say that it opens a picker.
            Semantics(
              button: true,
              label: _dueDate == null
                  ? 'Due date, none set'
                  : 'Due date, ${DateFormat('MMMM d, yyyy').format(_dueDate!)}',
              hint: 'Opens a date picker',
              child: InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: const OutlineInputBorder(),
                  helperText: 'When should this task be completed by?',
                  suffixIcon: _dueDate == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear due date',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _dueDate = null),
                        ),
                ),
                child: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, y').format(_dueDate!)
                      : 'Select a date',
                ),
              ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: taskCreationState.isLoading ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: taskCreationState.isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Create Task'),
            ),
            // Show error if any
            if (taskCreationState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.tokens.brick.withValues(alpha: 0.12),
                  border: Border.all(color: context.tokens.brick.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  taskCreationState.error!,
                  style: TextStyle(color: context.tokens.brick),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Effort size as a four-way segmented control.
///
/// This was a dropdown whose items read "Extra Large (XL) - Major tasks, 60+
/// minutes (100 ⭐)". At ~51 characters it truncated on every phone the app
/// runs on (an iPhone SE fits roughly 30), and `TextOverflow.ellipsis` turned
/// that into silent truncation rather than a visible error, hiding the star
/// value — the one number a parent is choosing between.
///
/// Four options don't need a menu. Showing them side by side makes the size
/// and its reward legible at 320pt, keeps every target ≥48px for the
/// touch-target floor, and moves the prose to a caption that can wrap.
class _EffortSizeField extends StatelessWidget {
  const _EffortSizeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TaskDifficulty value;
  final ValueChanged<TaskDifficulty> onChanged;

  static String shortLabel(TaskDifficulty d) => switch (d) {
        TaskDifficulty.easy => 'S',
        TaskDifficulty.medium => 'M',
        TaskDifficulty.hard => 'L',
        TaskDifficulty.challenging => 'XL',
      };

  static int stars(TaskDifficulty d) => switch (d) {
        TaskDifficulty.easy => 10,
        TaskDifficulty.medium => 25,
        TaskDifficulty.hard => 50,
        TaskDifficulty.challenging => 100,
      };

  static String description(TaskDifficulty d) => switch (d) {
        TaskDifficulty.easy => 'Small — quick tasks, 5-15 minutes',
        TaskDifficulty.medium => 'Medium — moderate tasks, 15-30 minutes',
        TaskDifficulty.hard => 'Large — complex tasks, 30-60 minutes',
        TaskDifficulty.challenging => 'Extra large — major tasks, 60+ minutes',
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Effort Size',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.02,
            color: t.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in TaskDifficulty.values) ...[
              Expanded(
                child: _EffortChip(
                  difficulty: d,
                  selected: d == value,
                  onTap: () => onChanged(d),
                ),
              ),
              if (d != TaskDifficulty.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // The prose that used to be crammed into the dropdown row. Full width
        // and free to wrap, so it never needs an ellipsis.
        Text(
          description(value),
          style: TextStyle(fontSize: 14, color: t.inkSoft),
        ),
      ],
    );
  }
}

class _EffortChip extends StatelessWidget {
  const _EffortChip({
    required this.difficulty,
    required this.selected,
    required this.onTap,
  });

  final TaskDifficulty difficulty;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = _EffortSizeField.shortLabel(difficulty);
    final count = _EffortSizeField.stars(difficulty);

    return Semantics(
      button: true,
      selected: selected,
      label: '${_EffortSizeField.description(difficulty)}, $count stars',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          // 48px floor is the touch target; the content sets the real height.
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? t.marigold : t.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? t.marigold : t.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Selection is not carried by colour alone: the letter also goes
              // bold and the border thickens.
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? t.ink : t.inkSoft,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count ⭐',
                  style: TextStyle(
                    fontSize: 14,
                    color: selected ? t.ink : t.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
