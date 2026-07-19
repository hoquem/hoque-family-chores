import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_creation_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_list_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
import 'package:hoque_family_chores/di/riverpod_container.dart';
import 'package:hoque_family_chores/presentation/theme/app_tokens.dart';
import 'package:hoque_family_chores/domain/entities/task.dart';
import 'package:hoque_family_chores/domain/entities/user.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Add this import for TimeoutException

class AddTaskScreen extends ConsumerStatefulWidget {
  /// When non-null, the screen edits this existing task instead of creating a
  /// new one (title, description, effort, due date, photo-proof). Assignment is
  /// not changed here — that is done via claim/unclaim on the task.
  final Task? existingTask;

  const AddTaskScreen({super.key, this.existingTask});

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
  bool _requiresPhotoProof = false;
  final _logger = AppLogger();

  bool get _isEditing => widget.existingTask != null;

  /// The task version this edit is based on. Lives in State (not the widget
  /// field) so a "reload after conflict" can advance it — otherwise every retry
  /// would re-submit the stale base and conflict forever.
  int _baseVersion = 0;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTask;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _dueDate = existing.dueDate;
      _selectedDifficulty = existing.difficulty;
      _requiresPhotoProof = existing.requiresPhotoProof;
      _baseVersion = existing.version;
    }
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

    if (_isEditing) {
      await _saveEdits(currentUser);
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
        requiresPhotoProof: _requiresPhotoProof,
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

  Future<void> _saveEdits(User currentUser) async {
    final existing = widget.existingTask!;
    _logger.i('Editing task ${existing.id.value} (base v$_baseVersion)');

    final outcome = await ref
        .read(taskListNotifierProvider(currentUser.familyId).notifier)
        .editTaskDetails(
          taskId: existing.id.value,
          baseVersion: _baseVersion,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          difficulty: _selectedDifficulty,
          dueDate: _dueDate ?? existing.dueDate,
          requiresPhotoProof: _requiresPhotoProof,
        );

    if (!mounted) return;
    switch (outcome) {
      case TaskEditOutcome.success:
        Navigator.of(context).pop(true);
      case TaskEditOutcome.conflict:
        await _handleEditConflict(currentUser);
      case TaskEditOutcome.deleted:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('This task was removed by someone else.'),
            backgroundColor: context.tokens.brickDeep,
          ),
        );
        Navigator.of(context).pop(true);
      case TaskEditOutcome.failure:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not save changes. Please try again.'),
            backgroundColor: context.tokens.brickDeep,
          ),
        );
    }
  }

  /// A concurrent edit landed first. Offer to reload the latest version so the
  /// parent isn't stuck resubmitting a stale base version forever.
  Future<void> _handleEditConflict(User currentUser) async {
    final reload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Task changed'),
        content: const Text(
          'Someone else changed this task while you were editing it. Reload the '
          'latest version? Your unsaved changes here will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reload'),
          ),
        ],
      ),
    );
    if (reload == true) {
      await _reloadFromServer(currentUser);
    }
  }

  Future<void> _handleUnassign() async {
    final currentUser = ref.read(authNotifierProvider).user;
    if (currentUser == null) return;
    try {
      _logger.i('Unassigning task ${widget.existingTask!.id.value}');
      await ref
          .read(taskListNotifierProvider(currentUser.familyId).notifier)
          .unassignTask(widget.existingTask!.id.value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('↩️ Task returned to the pool'),
            backgroundColor: context.tokens.carrotDeep,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _logger.e('Error unassigning task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unassign: ${e.toString()}'),
            backgroundColor: context.tokens.brickDeep,
          ),
        );
      }
    }
  }

  Future<void> _reloadFromServer(User currentUser) async {
    final latest = await ref
        .read(taskRepositoryProvider)
        .getTask(currentUser.familyId, widget.existingTask!.id);
    if (!mounted || latest == null) return;
    setState(() {
      _titleController.text = latest.title;
      _descriptionController.text = latest.description;
      _dueDate = latest.dueDate;
      _selectedDifficulty = latest.difficulty;
      _requiresPhotoProof = latest.requiresPhotoProof;
      _baseVersion = latest.version;
    });
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Add New Task')),
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
            SwitchListTile(
              key: const Key('photo_proof_switch'),
              value: _requiresPhotoProof,
              onChanged: (v) => setState(() => _requiresPhotoProof = v),
              title: Text(
                'Requires photo proof',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              subtitle: Text(
                'Ask for a photo before starting and after finishing',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            // Family members dropdown — hidden when editing (assignment is
            // changed via claim/unclaim on the task, not here).
            if (!_isEditing && familyMembersAsync != null) ...[
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
            ] else if (!_isEditing) ...[
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Task'),
            ),
            // A parent editing a task can send it back to the pool. Shown only
            // while it is actively assigned (not once completed/approved).
            if (_isEditing &&
                (widget.existingTask!.status == TaskStatus.assigned ||
                    widget.existingTask!.status == TaskStatus.inProgress ||
                    widget.existingTask!.status == TaskStatus.needsRevision)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _handleUnassign,
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Unassign (return to the pool)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
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
