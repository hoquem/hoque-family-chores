import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoque_family_chores/models/task.dart';
import 'package:hoque_family_chores/models/family_member.dart';
import 'package:hoque_family_chores/presentation/providers/auth_provider.dart';
import 'package:hoque_family_chores/presentation/providers/task_list_provider.dart';
import 'package:hoque_family_chores/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:hoque_family_chores/presentation/providers/family_provider.dart';
import 'dart:async'; // Add this import for TimeoutException

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  FamilyMember? _selectedAssignee;
  TaskDifficulty _selectedDifficulty = TaskDifficulty.easy;
  bool _isLoading = false;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final taskListProvider = context.read<TaskListProvider>();
      final familyId = authProvider.userFamilyId;
      final creatorId = authProvider.currentUserId;

      if (familyId == null || creatorId == null) {
        throw Exception('User not properly authenticated');
      }

      _logger.i('Creating new task for family $familyId by user $creatorId');

      final task = Task(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        points: _selectedDifficulty == TaskDifficulty.easy ? 10 :
                _selectedDifficulty == TaskDifficulty.medium ? 25 :
                _selectedDifficulty == TaskDifficulty.hard ? 50 : 100,
        difficulty: _selectedDifficulty,
        status: TaskStatus.available,
        familyId: familyId,
        assignedTo: _selectedAssignee,
        createdAt: DateTime.now(),
        dueDate: _dueDate ?? DateTime.now(),
        tags: const [],
      );

      _logger.d('Task object created: ${task.toJson()}');

      // Add timeout to task creation
      await Future.any([
        taskListProvider.createTask(familyId: familyId, task: task),
        Future.delayed(const Duration(seconds: 10)).then((_) {
          throw TimeoutException('Task creation timed out after 10 seconds');
        }),
      ]);

      _logger.i('Task created successfully');

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on TimeoutException catch (e) {
      _logger.e('Task creation timed out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task creation timed out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e, s) {
      _logger.e('Error creating task: $e', error: e, stackTrace: s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating task: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFamilyMembers() async {
    final authProvider = context.read<AuthProvider>();
    final familyProvider = context.read<FamilyProvider>();
    final familyId = authProvider.userFamilyId;

    if (familyId != null) {
      await familyProvider.loadFamilyMembers(familyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final familyMembers = familyProvider.familyMembers;
    final currentUser = authProvider.currentUser;

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
              value: _selectedDifficulty,
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
            DropdownButtonFormField<FamilyMember?>(
              decoration: const InputDecoration(
                labelText: 'Assign To (Optional)',
                border: OutlineInputBorder(),
              ),
              value: _selectedAssignee,
              items: [
                const DropdownMenuItem<FamilyMember?>(
                  value: null,
                  child: Text('Leave Unassigned'),
                ),
                if (currentUser != null)
                  DropdownMenuItem<FamilyMember?>(
                    value: currentUser.member,
                    child: Text('Me (${currentUser.member.name})'),
                  ),
                ...familyMembers
                    .where((member) => member.id != currentUser?.member.id)
                    .map((member) => DropdownMenuItem<FamilyMember?>(
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
              onPressed: _isLoading ? null : _submitTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}
