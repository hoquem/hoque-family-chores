import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/auth_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/task_creation_notifier.dart';
import 'package:hoque_family_chores/presentation/providers/riverpod/family_notifier.dart';
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
        const SnackBar(
          content: Text('User not properly authenticated'),
          backgroundColor: Colors.red,
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

      _logger.i('Task created successfully');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _logger.e('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: ${e.toString()}'),
            backgroundColor: Colors.red,
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
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskDifficulty>(
              decoration: const InputDecoration(
                labelText: 'Effort Size',
                border: OutlineInputBorder(),
                helperText: 'Select the effort size - points are automatically set',
              ),
              initialValue: _selectedDifficulty,
              items: TaskDifficulty.values.map((difficulty) {
                String description;
                int points;
                switch (difficulty) {
                  case TaskDifficulty.easy:
                    description = 'Small (S) - Quick tasks, 5-15 minutes';
                    points = 10;
                    break;
                  case TaskDifficulty.medium:
                    description = 'Medium (M) - Moderate tasks, 15-30 minutes';
                    points = 25;
                    break;
                  case TaskDifficulty.hard:
                    description = 'Large (L) - Complex tasks, 30-60 minutes';
                    points = 50;
                    break;
                  case TaskDifficulty.challenging:
                    description = 'Extra Large (XL) - Major tasks, 60+ minutes';
                    points = 100;
                    break;
                }
                return DropdownMenuItem<TaskDifficulty>(
                  value: difficulty,
                  child: Text('$description ($points points)'),
                );
              }).toList(),
              onChanged: (TaskDifficulty? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedDifficulty = newValue;
                  });
                }
              },
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
                  initialValue: _selectedAssignee,
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
                  ),
                  initialValue: null,
                  items: const [],
                  onChanged: null,
                ),
                error: (error, stack) => DropdownButtonFormField<User?>(
                  decoration: const InputDecoration(
                    labelText: 'Assign To (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: null,
                  items: const [],
                  onChanged: null,
                ),
              ),
            ] else ...[
              DropdownButtonFormField<User?>(
                decoration: const InputDecoration(
                  labelText: 'Assign To (Optional)',
                  border: OutlineInputBorder(),
                ),
                initialValue: null,
                items: const [],
                onChanged: null,
              ),
            ],
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Due Date (Approximate Time to Complete)',
                  border: OutlineInputBorder(),
                  helperText: 'When should this task be completed by?',
                ),
                child: Text(
                  _dueDate != null
                      ? DateFormat('MMM d, y').format(_dueDate!)
                      : 'Select a date',
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
                  ? const CircularProgressIndicator()
                  : const Text('Create Task'),
            ),
            // Show error if any
            if (taskCreationState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  taskCreationState.error!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
